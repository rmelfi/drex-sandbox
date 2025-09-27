import "@nomicfoundation/hardhat-ethers";
import { network } from "hardhat";
const { ethers } = await network.connect();

const BRL = (v: string) => ethers.parseUnits(v, 2); // 2 casas
const fmt = (v: bigint) => (Number(v) / 100).toFixed(2);

async function main() {
  const [
    deployer,
    authority,   // tem ACCESS_ROLE no RealDigital constructor
    admin,       // DEFAULT_ADMIN_ROLE
    buyer,
    seller,
    marketplace,
    cbsTreasury,
    ibsTreasury,
  ] = await ethers.getSigners();

  console.log("Deployer   :", await deployer.getAddress());
  console.log("Authority  :", await authority.getAddress());
  console.log("Admin      :", await admin.getAddress());
  console.log("Buyer      :", await buyer.getAddress());
  console.log("Seller     :", await seller.getAddress());
  console.log("Marketplace:", await marketplace.getAddress());
  console.log("CBS Tres.  :", await cbsTreasury.getAddress());
  console.log("IBS Tres.  :", await ibsTreasury.getAddress());

  // 1) RealDigital
  const RealDigital = await ethers.getContractFactory("RealDigital");
  const cbdc = await RealDigital.deploy(
    "Real Digital",
    "BRL",
    await authority.getAddress(),
    await admin.getAddress()
  );
  await cbdc.waitForDeployment();
  const cbdcAddr = await cbdc.getAddress();
  console.log("RealDigital:", cbdcAddr);

  // 2) Roles: dar MINTER_ROLE ao authority (deployer tem DEFAULT_ADMIN_ROLE)
  const MINTER_ROLE = ethers.id("MINTER_ROLE");
  await cbdc.connect(deployer).grantRole(MINTER_ROLE, await authority.getAddress());
  console.log("→ MINTER_ROLE ao authority");

  // 3) Habilitar contas que transacionarão (antes de mint/transfer)
  const enable = async (a: string) => cbdc.connect(authority).enableAccount(a);
  await enable(await buyer.getAddress());
  await enable(await seller.getAddress());
  await enable(await marketplace.getAddress());
  await enable(await cbsTreasury.getAddress());
  await enable(await ibsTreasury.getAddress());
  console.log("→ buyer/seller/marketplace/CBS/IBS habilitados");

  // 4) Deploy SplitCheckout
  const SplitCheckout = await ethers.getContractFactory("SplitCheckout");
  // default: CBS 12%, IBS 13%, fee 2%  -> total 27%
  const defaultCBS = 1200, defaultIBS = 1300, defaultFee = 200;
  const split = await SplitCheckout.deploy(
    cbdcAddr,
    await deployer.getAddress(),      // admin
    await marketplace.getAddress(),   // marketplace
    await cbsTreasury.getAddress(),   // CBS
    await ibsTreasury.getAddress(),   // IBS
    defaultCBS, defaultIBS, defaultFee
  );
  await split.waitForDeployment();
  const splitAddr = await split.getAddress();
  console.log("SplitCheckout:", splitAddr);

  // habilitar o contrato split (ele recebe tokens antes de redistribuir)
  await enable(splitAddr);
  console.log("→ SplitCheckout habilitado");

  // 5) Mint para o buyer (saldo para compras)
  await cbdc.connect(authority).mint(await buyer.getAddress(), BRL("10000")); // R$ 10.000,00
  console.log("Saldo buyer (inicial):", fmt(await cbdc.balanceOf(await buyer.getAddress())));

  // 6) (Opcional) alíquota por código (ex.: serviço educação com CBS reduzida)
  const code = ethers.id("SERVICO:EDUCACAO"); // exemplo de “código” do item
  await (await split.connect(deployer).setCodeRates(code, 600, 800, 150)).wait();
  // Agora para esse código: CBS 6%, IBS 8%, Fee 1.5%

  // 7) Simulação prévia
  const amount = BRL("1000"); // compra de R$ 1.000,00
  const sim = await split.simulateSplit(amount, code);
  console.log(`Simulação (R$ 1000,00, EDUCACAO): seller=${fmt(sim[0])} fee=${fmt(sim[1])} cbs=${fmt(sim[2])} ibs=${fmt(sim[3])}`);

  // 8) Approve + Pay
  await cbdc.connect(buyer).approve(splitAddr, amount);
  console.log("approve OK");
  await (await split.connect(buyer).payWithCode(await seller.getAddress(), amount, code)).wait();
  console.log("payWithCode OK");

  // 9) Saldos finais
  const balBuyer = await cbdc.balanceOf(await buyer.getAddress());
  const balSeller = await cbdc.balanceOf(await seller.getAddress());
  const balMkt   = await cbdc.balanceOf(await marketplace.getAddress());
  const balCBS   = await cbdc.balanceOf(await cbsTreasury.getAddress());
  const balIBS   = await cbdc.balanceOf(await ibsTreasury.getAddress());
  console.log("Saldo buyer      :", fmt(balBuyer));
  console.log("Saldo seller     :", fmt(balSeller));
  console.log("Saldo marketplace:", fmt(balMkt));
  console.log("Saldo CBS        :", fmt(balCBS));
  console.log("Saldo IBS        :", fmt(balIBS));
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});

