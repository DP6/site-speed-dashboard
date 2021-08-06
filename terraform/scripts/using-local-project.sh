
#!/bin/bash
echo "Executando $0  com os parâmetros versão=$1  e bucket=$2"
echo "Acessando diretorio raiz da cloudfunctio PSI do projeto"
cd ../functions/psi
FILE_NAME_PSI="$1-psi.zip"
echo "" pwd
echo "Criando Zip PSI"
zip -r $FILE_NAME_PSI package.json index.js README.md
echo "Movendo Zip para terraform/files-copy-to-gcs/config/"
mv $FILE_NAME_PSI ./../../terraform/files-copy-to-gcs/config/

echo "Acessando diretorio raiz da cloudfunctio CRUX do projeto"
cd ../crux
FILE_NAME_CRUX="$1-crux.zip"
zip -r $FILE_NAME_CRUX *
echo "Movendo Zip para terraform/files-copy-to-gcs/config/"
mv $FILE_NAME_CRUX ./../../terraform/files-copy-to-gcs/config/

echo "Entrando nas pasta terraform para copiar os arquivos"
cd ./../../terraform
echo "Iniciando copia para GCP"
gsutil cp -r ./files-copy-to-gcs/* "gs://$2"
echo "excluindo zip"
cd ./files-copy-to-gcs/config
rm -rf *.zip
echo "FIM script $0"
