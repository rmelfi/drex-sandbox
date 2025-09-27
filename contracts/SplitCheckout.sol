// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Interface mínima ERC-20 (RealDigital: 2 casas decimais)
interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address a) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address owner, address to, uint256 amount) external returns (bool);
}

/// @title SplitCheckout (CBS+IBS) — compatível com Real Digital (2 casas)
/// @notice Divide um pagamento em: vendedor, marketplace (taxa) e cofres fiscais (CBS/IBS).
///         Alíquotas em bps (basis points). Suporta tabela por código (ex.: NCM/serviço).
contract SplitCheckout {
    struct Rates {
        uint16 cbsBps;   // ex.: 1200 = 12.00%
        uint16 ibsBps;   // ex.: 1300 = 13.00%
        uint16 feeBps;   // marketplace fee, ex.: 200 = 2.00%
        bool   set;      // se é um registro válido
    }

    IERC20  public immutable token;        // RealDigital
    address public admin;                  // quem configura taxas e destinos
    address public marketplace;            // recebe fee
    address public cbsTreasury;            // cofre CBS
    address public ibsTreasury;            // cofre IBS

    // Alíquotas padrão (fallback)
    Rates public defaultRates;

    // Alíquotas por código (NCM/serviço/etc.)
    mapping(bytes32 => Rates) public codeRates;

    event Paid(
        address indexed payer,
        address indexed seller,
        uint256 gross,
        uint256 sellerNet,
        uint256 fee,
        uint256 cbs,
        uint256 ibs,
        bytes32 code
    );

    event SetDefaultRates(uint16 cbsBps, uint16 ibsBps, uint16 feeBps);
    event SetCodeRates(bytes32 indexed code, uint16 cbsBps, uint16 ibsBps, uint16 feeBps);
    event SetDestinations(address marketplace, address cbsTreasury, address ibsTreasury);
    event SetAdmin(address indexed newAdmin);

    modifier onlyAdmin() { require(msg.sender == admin, "only admin"); _; }

    constructor(
        address _token,
        address _admin,
        address _marketplace,
        address _cbsTreasury,
        address _ibsTreasury,
        uint16 _cbsBps,
        uint16 _ibsBps,
        uint16 _feeBps
    ) {
        require(_token != address(0) && _admin != address(0), "zero addr");
        require(_marketplace != address(0) && _cbsTreasury != address(0) && _ibsTreasury != address(0), "zero addr");
        token = IERC20(_token);
        admin = _admin;
        marketplace = _marketplace;
        cbsTreasury = _cbsTreasury;
        ibsTreasury = _ibsTreasury;

        // RealDigital tem 2 casas — reforço para evitar confusão
        require(token.decimals() == 2, "token decimals != 2");

        defaultRates = Rates({
            cbsBps: _cbsBps,
            ibsBps: _ibsBps,
            feeBps: _feeBps,
            set: true
        });
        emit SetDefaultRates(_cbsBps, _ibsBps, _feeBps);
        emit SetDestinations(_marketplace, _cbsTreasury, _ibsTreasury);
    }

    // --- Governança / Config ---

    function setAdmin(address _new) external onlyAdmin {
        require(_new != address(0), "zero addr");
        admin = _new;
        emit SetAdmin(_new);
    }

    function setDestinations(address _marketplace, address _cbsTreasury, address _ibsTreasury) external onlyAdmin {
        require(_marketplace != address(0) && _cbsTreasury != address(0) && _ibsTreasury != address(0), "zero addr");
        marketplace = _marketplace;
        cbsTreasury = _cbsTreasury;
        ibsTreasury = _ibsTreasury;
        emit SetDestinations(_marketplace, _cbsTreasury, _ibsTreasury);
    }

    function setDefaultRates(uint16 _cbsBps, uint16 _ibsBps, uint16 _feeBps) external onlyAdmin {
        defaultRates = Rates({ cbsBps: _cbsBps, ibsBps: _ibsBps, feeBps: _feeBps, set: true });
        emit SetDefaultRates(_cbsBps, _ibsBps, _feeBps);
    }

    /// @param code hash/código do item/serviço (ex.: keccak256(bytes("NCM:xxxxxx")))
    function setCodeRates(bytes32 code, uint16 _cbsBps, uint16 _ibsBps, uint16 _feeBps) external onlyAdmin {
        codeRates[code] = Rates({ cbsBps: _cbsBps, ibsBps: _ibsBps, feeBps: _feeBps, set: true });
        emit SetCodeRates(code, _cbsBps, _ibsBps, _feeBps);
    }

    // --- Pagamento ---

    /// @notice simula o split para exibição/UX antes da compra
    function simulateSplit(uint256 amount, bytes32 code)
        external
        view
        returns (uint256 sellerNet, uint256 fee, uint256 cbs, uint256 ibs)
    {
        Rates memory r = codeRates[code].set ? codeRates[code] : defaultRates;
        (sellerNet, fee, cbs, ibs) = _split(amount, r);
    }

    /// @notice paga um item sem código específico (usa defaultRates)
    function pay(address seller, uint256 amount) external returns (uint256 sellerNet, uint256 fee, uint256 cbs, uint256 ibs) {
        return payWithCode(seller, amount, bytes32(0));
    }

    /// @notice paga um item com código (usa codeRates[code] se existir; senão usa default)
    /// @dev é preciso que o pagador tenha feito approve(address(this), amount) antes.
    function payWithCode(address seller, uint256 amount, bytes32 code)
        public
        returns (uint256 sellerNet, uint256 fee, uint256 cbs, uint256 ibs)
    {
        require(seller != address(0), "seller=0");
        require(amount > 0, "amount=0");

        Rates memory r = codeRates[code].set ? codeRates[code] : defaultRates;
        (sellerNet, fee, cbs, ibs) = _split(amount, r);

        // Puxa fundos do comprador
        bool ok = token.transferFrom(msg.sender, address(this), amount);
        require(ok, "transferFrom failed");

        // Envia para destinos
        require(token.transfer(seller, sellerNet), "seller transfer failed");
        if (fee > 0) require(token.transfer(marketplace, fee), "fee transfer failed");
        if (cbs > 0) require(token.transfer(cbsTreasury, cbs), "cbs transfer failed");
        if (ibs > 0) require(token.transfer(ibsTreasury, ibs), "ibs transfer failed");

        emit Paid(msg.sender, seller, amount, sellerNet, fee, cbs, ibs, code);
    }

    // --- Internals ---

    /// @dev arredondamento "half up" por centavo: (x*bps + 50) / 10000
    function _bps(uint256 amount, uint16 bps) internal pure returns (uint256) {
        if (bps == 0) return 0;
        return (amount * uint256(bps) + 50) / 10_000;
    }

    function _split(uint256 amount, Rates memory r)
        internal
        pure
        returns (uint256 sellerNet, uint256 fee, uint256 cbs, uint256 ibs)
    {
        fee = _bps(amount, r.feeBps);
        cbs = _bps(amount, r.cbsBps);
        ibs = _bps(amount, r.ibsBps);
        uint256 totalDeductions = fee + cbs + ibs;
        require(totalDeductions <= amount, "overdeduct");
        sellerNet = amount - totalDeductions;
    }
}

