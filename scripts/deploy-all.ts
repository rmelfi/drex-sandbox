import "@nomicfoundation/hardhat-ethers";
import { network } from "hardhat";
const { ethers } = await network.connect();

const id = (s: string) => ethers.id(s);
const ZERO =
  "0x0000000000000000000000000000000000000000000000000000000000000000";

async function main() {
  const [deployer, authority, admin, participant] = await ethers.getSigners();

  console.log("Deployer   :", await deployer.getAddress());
  console.log("Authority  :", await authority.getAddress());
  console.log("Admin      :", await admin.getAddress());
  console.log("Participant:", await participant.getAddress());

  // 1) RealDigital
  const RealDigital = await ethers.getContractFactory("RealDigital");
  const cbdc = await RealDigital.deploy(
    "Real Digital",
    "BRL",
    await authority.getAddress(),
    await admin.getAddress()
  );
  await cbdc.waitForDeployment();
  const cbdcAddress = await cbdc.getAddress();
  console.log("RealDigital:", cbdcAddress);

  // (opcional) dar DEFAULT_ADMIN ao deployer
  try {
    await cbdc.connect(authority).grantRole(ZERO, await deployer.getAddress());
    await cbdc.connect(admin).grantRole(ZERO, await deployer.getAddress());
    console.log("→ DEFAULT_ADMIN para deployer (ok)");
  } catch {}

  // 2) STR
  const STR = await ethers.getContractFactory("STR");
  const str = await STR.deploy(cbdcAddress);
  await str.waitForDeployment();
  const strAddress = await str.getAddress();
  console.log("STR        :", strAddress);

  // 3) Roles para STR (se existirem)
  for (const role of [id("MINTER_ROLE"), id("MOVER_ROLE"), id("BURNER_ROLE")]) {
    try {
      await cbdc.grantRole(role, strAddress);
      console.log("→ grantRole OK:", role.slice(0, 10), "…");
    } catch {}
  }

  // 4) Autorizar participant — **como authority** (tem ACCESS_ROLE pela base)
  try {
    await cbdc.connect(authority).enableAccount(await participant.getAddress());
    console.log("→ participant autorizado via enableAccount(address) por authority");
  } catch (e: any) {
    console.log("→ não foi possível autorizar participant:", e?.message || e);
  }

  // 5) Smoke test
  try {
    await str.connect(participant).requestToMint(12345n);
    await str.connect(participant).requestToBurn(100n);
    const bal = await cbdc.balanceOf(await participant.getAddress());
    console.log("Saldo participant:", bal.toString());
  } catch (e: any) {
    console.log("Smoke test falhou:", e?.shortMessage || e?.reason || e?.message);
  }
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});

