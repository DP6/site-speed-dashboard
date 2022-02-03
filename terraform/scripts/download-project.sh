
#!/bin/bash
echo "Executando $0  com os parâmetros versão=$1 e bucket=$2"
curl "https://codeload.github.com/DP6/site-speed-dashboard/zip/$1" --output code.zip
unzip code.zip
rm -f code.zip

FILE_NAME_PSI="$1.zip"
FILE_NAME_CRUX="crux_data.zip"

cd site-speed-dashboard-"$1"/functions/psi
zip -r $FILE_NAME_PSI package.json index.js README.md
echo "Movendo Zip para terraform/files-copy-to-gcs/config/"
mv $FILE_NAME_PSI ./../../terraform/files-copy-to-gcs/config/

cd ../crux
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