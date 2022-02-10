# Site Speed Dashboard

<div align="center">
<img src="https://raw.githubusercontent.com/DP6/templates-centro-de-inovacoes/main/public/images/centro_de_inovacao_dp6.png" height="100px" />
</div>

<p align="center">
  <a href="#badge">
    <img alt="semantic-release" src="https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg">
  </a>
  <a href="https://www.codacy.com/gh/DP6/3ef6b0f421634cb881539914e7fa59f1/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=DP6/{{repo}}&amp;utm_campaign=Badge_Coverage"><img alt="Code coverage" src="https://app.codacy.com/project/badge/Coverage/3ef6b0f421634cb881539914e7fa59f1"/></a>
  <a href="#badge">
    <img alt="Test" src="https://github.com/dp6/site-speed-dashboard/actions/workflows/test.yml/badge.svg">
  </a>
  <a href="https://www.codacy.com/gh/DP6/site-speed-dashboard/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=DP6/site-speed-dashboard&amp;utm_campaign=Badge_Grade">
    <img alt="Code quality" src="https://app.codacy.com/project/badge/Grade/3ef6b0f421634cb881539914e7fa59f1">
  </a>
</p>

<!--
<div align="center">
<img src="https://raw.githubusercontent.com/DP6/templates-centro-de-inovacoes/main/public/images/centro_de_inovacao_dp6.png" height="100px" />
</div>

<p align="center">
  <a href="#badge">
    <img alt="semantic-release" src="https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg">
  </a>
  <a href="https://www.codacy.com/gh/DP6/{{token-codacy}}/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=DP6/{{repo}}&amp;utm_campaign=Badge_Coverage"><img alt="Code coverage" src="https://app.codacy.com/project/badge/Coverage/{{token-codacy}}"/></a>
  <a href="#badge">
    <img alt="Test" src="https://github.com/dp6/{{repo}}/actions/workflows/test.yml/badge.svg">
  </a>
  <a href="https://www.codacy.com/gh/DP6/{{repo}}/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=DP6/{{repo}}&amp;utm_campaign=Badge_Grade">
    <img alt="Code quality" src="https://app.codacy.com/project/badge/Grade/{{token-codacy}}">
  </a>
</p>
-->

{{Texto introdutorio}}

## Entendendo os running do NPM

- **unit-test**: Realiza uma bateria de testes unitários dos arquivos de js presentes na pasta test/unit;
- **integration-test**: Realiza uma bateria de testes de integração dos arquivos de js presentes na pasta test/integration;
- **all-test**:Realiza uma bateria de todos os testes presentes na pasta test/;
- **test**: alias para o comando `all-test`;
- **lint-md**: Submete o código a markdown a uma avaliação do `remark`;
- **lint-prettier**: Submete o código a uma avaliação utilizando o [Prettier](https://prettier.io/), de acordo com a configuração descrita no arquivo .prettierrc;,
- **lint**: Alias para executar todos os lints;
- **format**: Formata todo o código do projeto, utilizando o [Prettier](https://prettier.io/), de acordo com a configuração descrita no arquivo .prettierrc;
- **coverage**: Análise da cobertura dos testes;
- **local**: Executa a cloud function localmente utilizando o functions-frameworks;
- **coverage**: "nyc --reporter=lcov --reporter=cobertura npm run unit-test",
- **docs**: Gera a documentção do código fonte seguindo o padrão do `jsdoc2md` aplicado no arquivo index.js, a doc é armanezada em docs/index.md",

## 1. Requisitos para utilização

### 1.1 Produtos do GCP

- BigQuery
- Cloud Storage
- Cloud Function
- Service account

### 1.2 Dependências ambiente local

1. [Google Cloud SDK](https://cloud.google.com/sdk/docs/install?hl=pt-br)
2. Pacotes zip, unzip e curl
3. [Criar service Account](https://cloud.google.com/iam/docs/creating-managing-service-accounts) com as permissões (Storage Object Admin, Cloud Functions Admin, BigQuery Admin e Service Account User)
4. Variável [GOOGLE_APPLICATION_CREDENTIALS](https://cloud.google.com/docs/authentication/getting-started#setting_the_environment_variable)
5. Instalar o [Terraform](https://www.terraform.io/downloads.html)
6. Habilitar os produtos no GCP Cloud Function, BigQuery, Cloud Build API, Cloud Resource Manager API, BigQuery Data Transfer API e Cloud Storage, para uso do BigQuery é necessário ter um billing ativo

_Observação:_ Utilizando o ambiente no [Google Cloud Shell](https://cloud.google.com/shell/docs) não é necessário fazer os **1**, **2**, **4** e **5**

## 2. Instalando

Clone o projeto do github para sua máquina local ou Cloud Shell

```console
git clone https://github.com/DP6/site-speed-dashboard.git
```

Para fazer deploy no GCP usando o Terraform, o utilize o shell script terraform_deploy

```console
cd site-speed-dashboard/
sh terraform_deploy.sh
```

## Como contribuir

Pull requests são bem-vindos! Nós vamos adorar ajuda para evoluir esse modulo. Sinta-se livre para navegar por issues abertas buscando por algo que possa fazer. Caso tenha uma nova feature ou bug, por favor abra uma nova issue para ser acompanhada pelo nosso time.

### Requisitos obrigatórios

Só serão aceitas contribuições que estiverem seguindo os seguintes requisitos:

- [Padrão de commit](https://www.conventionalcommits.org/en/v1.0.0/)

### Api Docs

- [Index.js](https://github.com/dp6/site-speed-dashboard/blob/master/docs/index.md)

## Suporte:

**DP6 Koopa-troopa Team**

_e-mail: <koopas@dp6.com.br>_

<img src="https://raw.githubusercontent.com/DP6/templates-centro-de-inovacoes/main/public/images/koopa.png" height="100px" width=50px/>
