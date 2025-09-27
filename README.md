# 💻 DREX Sandbox — Projeto de Teste Local

Este repositório é um guia simples para criar e rodar um **sandbox do DREX** localmente, usando [Hardhat 3](https://hardhat.org/) e [Ethers v6](https://docs.ethers.org/).

---

## 🚀 Começando

### 1. Pré-requisitos

- **Node.js 22+** (LTS)
- **npm**

```bash
node -v
npm -v
```

---

### 2. Instalação

Clone o repositório e instale as dependências:

```bash
git clone https://github.com/rmelfi/drex-sandbox.git
cd drex-sandbox
npm install
```

---

### 3. Compilar os contratos

```bash
npm run compile
```

Os artifacts serão gerados em `artifacts/`.

---

### 4. Rodar o nó local

Abra um terminal e rode:

```bash
npm run node
```

Isso inicia a blockchain local em `http://127.0.0.1:8545` com contas de teste pré-carregadas.

---

### 5. Deploy do RealDigital e STR

Em outro terminal:

```bash
npm run deploy
```

O script `scripts/deploy.ts` vai:

- Conectar ao nó local
- Obter três contas (`deployer`, `authority`, `admin`)
- Deployar o contrato `RealDigital.sol`
- Deployar o contrato `STR.sol`
- Mostrar os endereços no console

---

### 6. Testar funcionalidades

Há scripts de demonstração, como:

```bash
npx hardhat run --network localhost scripts/demo-buy-car.ts
npx hardhat run --network localhost scripts/demo-split.ts
```

Eles simulam:
- Habilitação de contas (`enableAccount`)
- Emissão (`requestToMint`)
- Transferência entre participantes
- Queima (`requestToBurn`)

---

## 🧠 Conceitos importantes

- **Hardhat**: framework para compilar, testar e rodar scripts de contratos Ethereum.
- **Ethers v6**: biblioteca para deploy e interação com contratos.
- **RealDigital.sol**: token ERC20 com **2 casas decimais**.
- **CBDCAccessControl.sol**: define papéis como `MINTER_ROLE`, `BURNER_ROLE`, `PAUSER_ROLE`, etc.
- **STR.sol**: contrato que chama `mint` e `burn` no RealDigital para participantes autorizados.

Sempre use `ethers.parseUnits(valor, 2)` para lidar com valores (por exemplo, `100.50` → `10050`).

---

## ⚠️ Avisos

- Este projeto é **somente para testes locais**.  
- As chaves privadas exibidas pelo Hardhat são de **desenvolvimento** e não devem ser usadas em produção.

---

## 📹 Vídeo

Gravei um passo a passo mostrando como usar este repositório do zero ao deploy:  
📽️ **Link do vídeo**: *[Video](https://www.linkedin.com/posts/rmelfi_sabadrex-code-activity-7377770275808903168-9WbQ?utm_source=share&utm_medium=member_desktop&rcm=ACoAAAKx-48B4RVo2ga2MYIzDQRXoM36EQ9l2d4)*


