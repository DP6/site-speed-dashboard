
#!/bin/bash
echo "Executando $0 com os parâmetros versão=$1 e bucket=$2"

FILE_NAME_PSI="$1.zip"
FILE_NAME_CRUX="crux_data.zip"

echo "Acessando diretorio raiz da Cloud Function PSI do projeto"
cd ../functions/psi
echo "Criando Zip PSI"
zip -r $FILE_NAME_PSI package.json index.js README.md
echo "Movendo Zip para terraform/files-copy-to-gcs/config/"
mv $FILE_NAME_PSI ./../../terraform/files-copy-to-gcs/config/

echo "Acessando diretorio raiz da Cloud Function CRUX do projeto"
cd ../crux
zip -r $FILE_NAME_CRUX *
echo "Movendo Zip para terraform/files-copy-to-gcs/config/"
mv $FILE_NAME_CRUX ./../../terraform/files-copy-to-gcs/config/

echo "Entrando nas pasta terraform para copiar os arquivos"
cd ./../../terraform

echo "Iniciando copia para GCP"
gsutil cp -r ./files-copy-to-gcs/* "gs://$2"

echo "Excluindo zip"
cd ./files-copy-to-gcs/config
rm -rf *.zip

echo "FIM script $0"