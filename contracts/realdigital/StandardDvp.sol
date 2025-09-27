// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./RealTokenizado.sol";
import "./RealDigital.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import  "./ApprovedDigitalCurrency.sol";

contract StandardDvp is ApprovedDigitalCurrency{

    using Counters for Counters.Counter;

    Counters.Counter private _proposalIdCounter;

    RealDigital CBDC;

    enum DvPStatus {
        PENDING,
        EXECUTED,
        CANCELLED
    }

    struct DvPProposal {
        address seller;
        address buyer;
        IERC1155 asset;
        uint256 assetId;
        uint256 quantity;
        RealTokenizado tokenPayer;
        RealTokenizado tokenPayee;
        uint256 pricePerUnit;
        uint256 amount;
        bytes data;
        DvPStatus status;
        bool sellerStart;
        uint timestamp;
    }

    struct AssetDetail {
        bool approved;
        uint timeout;
    }

    /**
     * _Mapping_ de propostas de DvP
     */
    mapping( uint256 => DvPProposal) dvpProposals;

    mapping( address => AssetDetail) approvedAssets;

    /**
     * Evento de inicio do DvP
     * @param id id do DvP
     * @param quantity quantidade
     * @param seller endereço do vendedor
     * @param buyer endereço do comprador
     * @param pricePerUnit preço por unidade
     * @param timestamp data e hora do inicio do DvP
     * @param data dados relacionados a operação
     */
    event DvPStarted(uint256 indexed id, uint256 quantity, address seller, address buyer, uint256 pricePerUnit, uint timestamp, bytes data);

    /**
     * Evento de execução do DvP
     * @param id id do DvP
     * @param quantity quantidade
     * @param seller endereço do vendedor
     * @param buyer endereço do comprador
     * @param pricePerUnit preço por unidade
     * @param timestamp data e hora do inicio do DvP
     * @param data dados relacionados a operação
     */
    event DvPExecuted(uint256 indexed id, uint256 quantity, address seller, address buyer, uint256 pricePerUnit, uint timestamp, bytes data);

    /**
     * Evento de cancelamento do DvP
     * @param id id do DvP
     * @param reason Razão do cancelamento
     */
    event DvPCancelled(uint256 indexed id, string reason);

    /**
     * Evento de proposta expirada. A proposta expira num tempo x configuravel por ativo
     * @param proposalId Id da proposta
     */
    event ExpiredProposal(uint256 proposalId);

    /**
     * Construtor
     * @param _CBDC Endereço do contrato do Real Digital
     */
    constructor (RealDigital _CBDC, address _authority, address _admin) ApprovedDigitalCurrency(_authority, _admin) {
        CBDC = _CBDC;
    }

    function setAssetsApproval(address assetAddress, bool approved, uint timeout) public onlyRole(ACCESS_ROLE) {
        require(timeout > 0, "StandardDvp: Timeout should be greater than 0");
        approvedAssets[assetAddress] = AssetDetail(approved,timeout);

    }

    function startDvp( IERC1155 asset, uint256 id, uint256 quantity, RealTokenizado tokenPayer, RealTokenizado tokenPayee,  address seller, address buyer, uint256 pricePerUnit, uint timestamp, bytes memory data) public {
        require(seller != address(0) && buyer != address(0),"StandardDvp: Buyer and seller should not be 0");
        require(seller == _msgSender() || buyer == _msgSender(), "StandardDvp: Only Buyer or seller can start dvp");
        require(tokenPayer.authorizedAccounts(buyer) && tokenPayee.authorizedAccounts(seller),"StandardDvp: Buyer and seller should be authorized");
        require(approvedAssets[address(asset)].approved,"StandardDvp: Asset should be approved");
        require(seller != buyer, "StandardDvp: Seller should not be equal buyer");
        require(quantity > 0,"StandardDvp: quantity should be greater than 0");
        require(pricePerUnit > 0,"StandardDvp: Price per unit should be greater than 0");
        require(asset.balanceOf(seller,id) >= quantity, "StandardDvp: Not enough asset balance");
        require(approvedDigitalCurrency[address(tokenPayer)] && approvedDigitalCurrency[address(tokenPayee)], "StandardDvp: Digital currency not allowed to DvP");

        uint256 dvpId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        uint256 amount = quantity * pricePerUnit;

        require(tokenPayer.balanceOf(buyer) >= amount,"StandardDvp: Not enough token balance");


        dvpProposals[dvpId] = DvPProposal(seller, buyer, asset, id, quantity, tokenPayer, tokenPayee, pricePerUnit,amount, data, DvPStatus.PENDING, false, timestamp);

        if (address(dvpProposals[dvpId].tokenPayer) != address(CBDC)) {
            require(CBDC.balanceOf(tokenPayer.reserve()) >= amount,"StandardDvp: Not enough CBDC balance");
        }

        if (seller == _msgSender()) {
            bool approved = asset.isApprovedForAll(_msgSender(), address(this));
            require(approved ,"StandardDvp: Asset not allowed to transfer from");
            dvpProposals[dvpId].sellerStart = true;
        }
        //event DvPStarted(uint256 indexed id, uint256 quantity, address seller, address buyer, uint256 pricePerUnit, uint timestamp, bytes data);
        emit DvPStarted(dvpId, quantity, seller, buyer, pricePerUnit, timestamp, data);

    }

    function executeDvp(uint256 dvpId, bytes memory data ) public {

        require(dvpProposals[dvpId].buyer == _msgSender() && dvpProposals[dvpId].sellerStart == true ||  dvpProposals[dvpId].seller == _msgSender() && dvpProposals[dvpId].sellerStart == false , "StandardDvp: Other side must complete the dvp");
        require(dvpProposals[dvpId].status == DvPStatus.PENDING, "StandardDvp: DvP status is not pending");
        require(keccak256(abi.encodePacked(dvpProposals[dvpId].data)) == keccak256(abi.encodePacked(data)) , "StandardDvp: Data should be equal from both sides");
        require(dvpProposals[dvpId].tokenPayer.authorizedAccounts(dvpProposals[dvpId].buyer) && dvpProposals[dvpId].tokenPayee.authorizedAccounts(dvpProposals[dvpId].seller),"StandardDvp: Buyer and seller should be authorized");
        require(dvpProposals[dvpId].asset.balanceOf(dvpProposals[dvpId].seller,dvpProposals[dvpId].assetId) >= dvpProposals[dvpId].quantity,"StandardDvp: Not enough asset balance");
        require(dvpProposals[dvpId].tokenPayer.balanceOf(dvpProposals[dvpId].buyer) >= dvpProposals[dvpId].amount,"StandardDvp: Not enough token balance");

        if (address(dvpProposals[dvpId].tokenPayer) != address(CBDC)) {
            require(CBDC.balanceOf(dvpProposals[dvpId].tokenPayer.reserve()) >= dvpProposals[dvpId].amount,"StandardDvp: Not enough CBDC balance");
        }

        // 1 hora = 3600
        if (block.timestamp - dvpProposals[dvpId].timestamp > approvedAssets[address(dvpProposals[dvpId].asset)].timeout) {
            emit ExpiredProposal(dvpId);
            revert("StandardDvp: Expired proposal");
        }

        dvpProposals[dvpId].status = DvPStatus.EXECUTED;

        if ( dvpProposals[dvpId].seller == _msgSender()) {

            require( dvpProposals[dvpId].sellerStart == false, "StandardDvp: Seller started the DvP");
            require( dvpProposals[dvpId].asset.isApprovedForAll(dvpProposals[dvpId].seller, address(this)),"StandardDvp: Asset not allowed to transfer from");

        }

        deliverAsset(dvpId);
        transferFunds(dvpId);
        emit DvPExecuted(dvpId,dvpProposals[dvpId].quantity,dvpProposals[dvpId].seller,dvpProposals[dvpId].buyer,dvpProposals[dvpId].pricePerUnit,dvpProposals[dvpId].timestamp,dvpProposals[dvpId].data);
    }

    function cancelDvp(uint256 dvpId, string calldata reason) public {
        if (block.timestamp - dvpProposals[dvpId].timestamp <= 3600) {
            require( dvpProposals[dvpId].buyer == _msgSender() || dvpProposals[dvpId].seller == _msgSender(), "StandardDvp: Other side must complete the dvp");
        }
        require( dvpProposals[dvpId].status == DvPStatus.PENDING, "StandardDvp: DvP is not pending");

        dvpProposals[dvpId].status = DvPStatus.CANCELLED;

        emit DvPCancelled(dvpId, reason);
    }

    function transferFunds(uint256 dvpId) internal {

        require(approvedDigitalCurrency[address(dvpProposals[dvpId].tokenPayer)] && approvedDigitalCurrency[address(dvpProposals[dvpId].tokenPayee)], "StandardDvp: Digital currency not allowed to DvP");

        if ( dvpProposals[dvpId].tokenPayee == dvpProposals[dvpId].tokenPayer){

                dvpProposals[dvpId].tokenPayee.transferFrom(dvpProposals[dvpId].buyer,dvpProposals[dvpId].seller,dvpProposals[dvpId].amount);

                } else {

                require(address(dvpProposals[dvpId].tokenPayer) != address(CBDC) && address(dvpProposals[dvpId].tokenPayee) != address(CBDC),"StandardDvp: Tokens should not be CBDC");
                dvpProposals[dvpId].tokenPayer.burnFrom(dvpProposals[dvpId].buyer, dvpProposals[dvpId].amount);
                CBDC.transferFrom(dvpProposals[dvpId].tokenPayer.reserve(), dvpProposals[dvpId].tokenPayee.reserve(), dvpProposals[dvpId].amount);
                dvpProposals[dvpId].tokenPayee.mint(dvpProposals[dvpId].seller, dvpProposals[dvpId].amount);
            }
    }

    function deliverAsset(uint256 dvpId) internal {

        dvpProposals[dvpId].asset.safeTransferFrom(dvpProposals[dvpId].seller,dvpProposals[dvpId].buyer,dvpProposals[dvpId].assetId,dvpProposals[dvpId].quantity,dvpProposals[dvpId].data);

    }
}
