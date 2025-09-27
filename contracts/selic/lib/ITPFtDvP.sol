// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ITPFt} from "../ITPFt.sol";
import {AddressDiscovery} from "../../realdigital/AddressDiscovery.sol";
import {RealTokenizado} from "../../realdigital/RealTokenizado.sol";
import {OperationType} from "./TPFtConstants.sol";

/**
 * @title ITPFtDvP
 * @author BCB
 * @notice Interface responsável por permitir transações de DvP (Entrega contra Pagamento)
 * entre participantes e entre clientes.
 */
interface ITPFtDvP is IAccessControl {
    /**
     * Estrutura que representa uma operação de DvP.
     * @param dvpId Identificador da operação DvP a ser executada.
     * @param buyer Endereço da carteira do comprador (cessionário).
     * @param buyerToken RealTokenizado do comprador.
     * @param seller Endereço da carteira do vendedor (cedente).
     * @param sellerToken RealTokenizado do vendedor.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser negociada na operação de DvP.
     * @param unitPrice Preço unitário do TPFt. Incluir as 8 casas decimais.
     * @param financialValue Quantidade de Real Digital / Real Tokenizado a ser negociada.
     * @param buyerOperation Valor booleano que indica se o comprador participou da operação.
     * @param sellerOperation Valor booleano que indica se o vendedor participou da operação.
     * @param canceled Valor booleano que indica se a operação foi cancelada.
     * @param executed Valor booleano que indica se a operação foi executada com sucesso.
     * @param extraData Dados adicionais da operação DvP.
     */
    struct DvPOperation {
        uint256 dvpId;
        address buyer;
        RealTokenizado buyerToken;
        address seller;
        RealTokenizado sellerToken;
        ITPFt.TPFtData tpftData;
        uint256 tpftAmount;
        uint256 unitPrice;
        uint256 financialValue;
        bool buyerOperation;
        bool sellerOperation;
        bool canceled;
        bool executed;
        bytes extraData;
    }

    /**
     * Realiza operação de DvP (Entrega contra Pagamento) entre Participantes.
     * @param dvpId Identificador da operação DvP a ser executada.
     * @param buyer Endereço da carteira do comprador.
     * @param seller Endereço da carteira do vendedor.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser negociada.
     * @param unitPrice Preço unitário do TPFt. Incluir as 8 casas decimais.
     * @param financialValue Quantidade de Real Digital a ser negociada.
     * @param operationType Tipo de operação. Se for compra deve ser informado OperationType.BUY, se for venda deve ser informado OperationType.SELL.
     * @return Retorna o número total de operações de DvP realizadas após a execução desta função.
     * @param extraData Dados adicionais da operação DvP.
     */
    function dvpParticipant(uint256 dvpId, address buyer, address seller, ITPFt.TPFtData memory tpftData, uint256 tpftAmount, uint256 unitPrice, uint256 financialValue, OperationType operationType, bytes memory extraData) external returns (uint256);

    /**
     * Realiza operação de DvP (Entrega contra Pagamento) entre Clientes.
     * @param dvpId Identificador da operação DvP a ser executada.
     * @param buyer Endereço da carteira do comprador.
     * @param buyerToken Real Tokenizado do comprador.
     * @param seller Endereço da carteira do vendedor.
     * @param sellerToken Real Tokenizado do vendedor.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser negociada.
     * @param unitPrice Preço unitário do TPFt. Incluir as 8 casas decimais.
     * @param financialValue Quantidade de Real Tokenizado a ser negociada.
     * @param operationType Tipo de operação. Se for compra deve ser informado OperationType.BUY, se for venda deve ser informado OperationType.SELL.
     * @return Retorna o número total de operações de DvP realizadas após a execução desta função.
     * @param extraData Dados adicionais da operação DvP.
     */
    function dvpClients(
        uint256 dvpId,
        address buyer,
        RealTokenizado buyerToken,
        address seller,
        RealTokenizado sellerToken,
        ITPFt.TPFtData memory tpftData,
        uint256 tpftAmount,
        uint256 unitPrice,
        uint256 financialValue,
        OperationType operationType,
        bytes memory extraData
    ) external returns (uint256);

    /**
     * Cancela uma operação DvP com o identificador dvpId.
     * @param dvpId Identificador da operação DvP.
     */
    function cancelDvP(uint256 dvpId) external;

    /**
     * Atualiza o contrato AddressDiscovery.
     * @param newAddressDiscovery Novo endereço do AddressDiscovery.
     */
    function updateAddressDiscovery(AddressDiscovery newAddressDiscovery) external;

    /**
     * Atualiza o contrato TPFt.
     * @param newTPFt Novo endereço do TPFt.
     */
    function updateTPFt(ITPFt newTPFt) external;

    /**
     * Retorna a operação DvP com o identificador dvpId.
     * @param dvpId Identificador da operação DvP.
     */
    function getDvPOperation(uint256 dvpId) external view returns (DvPOperation memory);

    /**
     * Retorna o número total de operações de DvP executadas.
     * @return Retorna o número total de operações de DvP executadas.
     */
    function getTotalDvPs() external view returns (uint256);

    /**
     * Retorna o contrato AddressDiscovery.
     * @return Retorna o contrato AddressDiscovery.
     */
    function getAddressDiscovery() external view returns (AddressDiscovery);

    /**
     * Retorna o contrato TPFt.
     * @return Retorna o contrato TPFt.
     */
    function getTPFt() external view returns (ITPFt);
}
