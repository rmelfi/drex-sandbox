import "@nomicfoundation/hardhat-ethers";
import { network } from "hardhat";
const { ethers } = await network.connect();

const BRL = (v: string) => ethers.parseUnits(v, 2); // RealDigital tem 2 casas decimais
const fmt = (v: bigint) => (Number(v) / 100).toFixed(2);

async function main() {
  const [deployer, authority, admin, buyer, seller, registrar] = await ethers.getSigners();

  console.log("Deployer :", await deployer.getAddress());
  console.log("Authority:", await authority.getAddress());
  console.log("Admin    :", await admin.getAddress());
  console.log("Buyer    :", await buyer.getAddress());
  console.log("Seller   :", await seller.getAddress());
  console.log("Registrar:", await registrar.getAddress());

  // 1) Deploy RealDigital
  const RealDigital = await ethers.getContractFactory("RealDigital");
  const cbdc = await RealDigital.deploy(
    "Real Digital",
    "BRL",
    await authority.getAddress(), // _authority (tem ACCESS_ROLE)
    await admin.getAddress()      // _admin     (DEFAULT_ADMIN_ROLE)
  );
  await cbdc.waitForDeployment();
  const cbdcAddr = await cbdc.getAddress();
  console.log("RealDigital:", cbdcAddr);

  // 2) Roles: dar MINTER_ROLE ao authority (deployer tem DEFAULT_ADMIN_ROLE)
  const MINTER_ROLE = ethers.id("MINTER_ROLE");
  await cbdc.connect(deployer).grantRole(MINTER_ROLE, await authority.getAddress());
  console.log("→ MINTER_ROLE dado ao authority");

  // 3) Habilitar contas que vão receber/enviar tokens (IMPORTANTE antes de qualquer mint/transfer)
  await cbdc.connect(authority).enableAccount(await buyer.getAddress());
  await cbdc.connect(authority).enableAccount(await seller.getAddress());
  console.log("→ buyer e seller habilitados (enableAccount)");

  // 4) Deploy CarEscrow (escrow de compra e venda do carro)
  //    Se ainda não tiver o contrato, use o CarEscrow.sol do exemplo que te enviei.
  const CarEscrow = await ethers.getContractFactory("CarEscrow");
  const carPriceBRL = "95000"; // preço do carro em reais
  const carPrice = BRL(carPriceBRL);
  const deadline = Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60; // +7 dias

  const escrow = await CarEscrow.deploy(
    cbdcAddr,
    await buyer.getAddress(),
    await seller.getAddress(),
    await registrar.getAddress(),
    carPrice,
    deadline
  );
  await escrow.waitForDeployment();
  const escrowAddr = await escrow.getAddress();
  console.log("CarEscrow :", escrowAddr);

  // 5) Habilitar o escrow também (ele receberá via transferFrom no fund())
  await cbdc.connect(authority).enableAccount(escrowAddr);
  console.log("→ escrow habilitado (enableAccount)");

  // 6) Mint para o buyer (authority tem MINTER_ROLE)
  const extra = BRL("2000"); // saldo extra (taxas, etc.)
  await cbdc.connect(authority).mint(await buyer.getAddress(), carPrice + extra);
  console.log("→ mint OK para buyer:", fmt(await cbdc.balanceOf(await buyer.getAddress())));

  // 7) Buyer aprova e funda o escrow
  await cbdc.connect(buyer).approve(escrowAddr, carPrice);
  console.log("→ approve OK");
  await escrow.connect(buyer).fund();
  console.log("→ fund OK  | saldo escrow:", fmt(await cbdc.balanceOf(escrowAddr)));
  console.log("Saldo buyer:", fmt(await cbdc.balanceOf(await buyer.getAddress())));

  // 8) Seller/Registrar: entrega e liberação
  const vin = "9BWZZZ377VT004251";
  const docHash = ethers.id("doc:CRV-transfer-#" + vin);
  await escrow.connect(seller).markDelivered(vin, docHash);
  console.log("→ markDelivered OK");
  await escrow.connect(registrar).confirmAndRelease();
  console.log("→ confirmAndRelease OK");

  // 9) Saldos finais
  const balBuyer = await cbdc.balanceOf(await buyer.getAddress());
  const balSeller = await cbdc.balanceOf(await seller.getAddress());
  const balEscrow = await cbdc.balanceOf(escrowAddr);
  console.log("Saldo seller:", fmt(balSeller));
  console.log("Saldo buyer :", fmt(balBuyer));
  console.log("Saldo escrow:", fmt(balEscrow));
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});

