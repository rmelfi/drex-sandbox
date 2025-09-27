// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Interface mínima ERC-20
interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address a) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address owner, address to, uint256 amount) external returns (bool);
}

contract CarEscrow {
    enum State { Created, Funded, Delivered, Released, Refunded, Canceled, Dispute }

    IERC20 public immutable token;         // RealDigital
    address public immutable buyer;
    address public immutable seller;
    address public immutable registrar;    // cartório/autoridade que confirma a transferência
    uint256 public immutable price;        // em centavos (2 casas decimais)
    uint256 public immutable deadline;     // timestamp limite para entrega/confirmar

    State   public state;
    string  public vin;                    // opcional: VIN do veículo
    bytes32 public deliveryDocHash;        // hash do documento de transferência (ex.: CRV)
    uint256 public fundedAt;

    // taxas/segurança (opcional)
    uint256 public cancellationFeeBps = 0; // taxa (%) * 1e-2, ex 50 = 0,50% (quem recebe: seller)

    event Funded(address indexed by, uint256 amount, uint256 at);
    event DeliveryMarked(address indexed by, string vin, bytes32 docHash);
    event Released(address to, uint256 amount);
    event Refunded(address to, uint256 amount);
    event Canceled(address by);
    event DisputeOpened(address by);
    event Resolved(string outcome);

    modifier onlyBuyer()     { require(msg.sender == buyer, "only buyer"); _; }
    modifier onlySeller()    { require(msg.sender == seller, "only seller"); _; }
    modifier onlyRegistrar() { require(msg.sender == registrar, "only registrar"); _; }
    modifier inState(State s){ require(state == s, "bad state"); _; }

    constructor(
        address _token,
        address _buyer,
        address _seller,
        address _registrar,
        uint256 _price,
        uint256 _deadline
    ) {
        require(_token != address(0) && _buyer != address(0) && _seller != address(0) && _registrar != address(0), "zero addr");
        require(_price > 0, "price=0");
        require(_deadline > block.timestamp, "deadline past");
        token = IERC20(_token);
        buyer = _buyer;
        seller = _seller;
        registrar = _registrar;
        price = _price;
        deadline = _deadline;
        state = State.Created;
        // sanity: precisa ter 2 casas (RealDigital)
        require(token.decimals() == 2, "token decimals != 2");
    }

    /// @notice comprador puxa os fundos para o escrow (precisa dar approve antes)
    function fund() external onlyBuyer inState(State.Created) {
        require(block.timestamp <= deadline, "deadline");
        require(token.allowance(buyer, address(this)) >= price, "approve first");
        bool ok = token.transferFrom(buyer, address(this), price);
        require(ok, "transferFrom failed");
        state = State.Funded;
        fundedAt = block.timestamp;
        emit Funded(msg.sender, price, fundedAt);
    }

    /// @notice vendedor (ou registrar) marca dados da entrega (vin + hash doc)
    function markDelivered(string calldata _vin, bytes32 _docHash) external inState(State.Funded) {
        require(msg.sender == seller || msg.sender == registrar, "only seller/registrar");
        vin = _vin;
        deliveryDocHash = _docHash;
        state = State.Delivered;
        emit DeliveryMarked(msg.sender, _vin, _docHash);
    }

    /// @notice registrar confirma a transferência e libera os fundos ao vendedor
    function confirmAndRelease() external onlyRegistrar inState(State.Delivered) {
        state = State.Released;
        bool ok = token.transfer(seller, price);
        require(ok, "release transfer failed");
        emit Released(seller, price);
    }

    /// @notice comprador pede reembolso se prazo expirou e não houve entrega
    function requestRefund() external onlyBuyer {
        require(state == State.Funded || state == State.Created, "cannot refund now");
        require(block.timestamp > deadline, "not expired");
        state = State.Refunded;
        uint256 refund = price;
        if (cancellationFeeBps > 0) {
            uint256 fee = (price * cancellationFeeBps) / 10_000;
            if (fee > 0) {
                // taxa vai pro vendedor
                require(token.transfer(seller, fee), "fee transfer failed");
                refund = price - fee;
            }
        }
        require(token.transfer(buyer, refund), "refund transfer failed");
        emit Refunded(buyer, refund);
    }

    /// @notice cancelar por acordo mútuo (antes do funding) — opcional
    function cancelByAgreement() external {
        require(state == State.Created, "not cancelable");
        require(msg.sender == buyer || msg.sender == seller, "only party");
        state = State.Canceled;
        emit Canceled(msg.sender);
    }

    /// @notice abrir disputa (qualquer parte), resolução via registrar
    function openDispute() external {
        require(msg.sender == buyer || msg.sender == seller, "only party");
        require(state == State.Funded || state == State.Delivered, "no dispute");
        state = State.Dispute;
        emit DisputeOpened(msg.sender);
    }

    /// @notice resolver disputa: registrar decide liberar ou reembolsar
    function resolveDispute(bool releaseToSeller) external onlyRegistrar inState(State.Dispute) {
        if (releaseToSeller) {
            state = State.Released;
            require(token.transfer(seller, price), "release transfer failed");
            emit Released(seller, price);
            emit Resolved("released");
        } else {
            state = State.Refunded;
            require(token.transfer(buyer, price), "refund transfer failed");
            emit Refunded(buyer, price);
            emit Resolved("refunded");
        }
    }
}

