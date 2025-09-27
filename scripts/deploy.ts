import "@nomicfoundation/hardhat-ethers";
import { network } from "hardhat";
const { ethers } = await network.connect();


async function main() {
  console.log("🚀 Iniciando deploy...");

  // Obter contas locais
  const [deployer, authority, admin] = await ethers.getSigners();

  console.log("👤 Deployer:", await deployer.getAddress());
  console.log("👤 Authority:", await authority.getAddress());
  console.log("👤 Admin:", await admin.getAddress());

  // 1) Deploy do RealDigital com os 4 argumentos obrigatórios
  const RealDigital = await ethers.getContractFactory("RealDigital");
  const cbdc = await RealDigital.deploy(
    "Real Digital",          // _name
    "BRL",                   // _symbol
    await authority.getAddress(), // _authority
    await admin.getAddress()      // _admin
  );
  await cbdc.waitForDeployment();
  const cbdcAddress = await cbdc.getAddress();
  console.log("✅ RealDigital deployed at:", cbdcAddress);

  // 2) Deploy do STR passando o endereço do RealDigital
  const STR = await ethers.getContractFactory("STR");
  const str = await STR.deploy(cbdcAddress);
  await str.waitForDeployment();
  console.log("✅ STR deployed at:", await str.getAddress());
}

// Executa o script
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

