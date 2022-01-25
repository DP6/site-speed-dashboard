
#!/bin/bash
echo "Executando $0 com os parâmetros versão=$1 e bucket=$2"

FILE_NAME_PSI="$1.zip"
FILE_NAME_CRUX="crux_data.zip"

if [ "$1" != "local" ]; then
    echo "Baixando o projeto"
    cd ../../
    curl "https://codeload.github.com/DP6/site-speed-dashboard/zip/$1" --output code.zip
    unzip code.zip
    rm -f code.zip

    echo "Acessando diretorio raiz da Cloud Function PSI do projeto"
    cd site-speed-dashboard-"$1"/functions/psi
else
    echo "Acessando diretorio raiz da Cloud Function PSI do projeto"
    cd ./../functions/psi
fi

echo "Criando Zip PSI"
zip -r $FILE_NAME_PSI package.json index.js README.md
echo "Movendo Zip para terraform/files-copy-to-gcs/config/"
mv $FILE_NAME_PSI ./../../../site-speed-dashboard/terraform/files-copy-to-gcs/config/

echo "Acessando diretorio raiz da Cloud Function CRUX do projeto"
cd ../crux
zip -r $FILE_NAME_CRUX *
echo "Movendo Zip para terraform/files-copy-to-gcs/config/"
mv $FILE_NAME_CRUX ./../../../site-speed-dashboard/terraform/files-copy-to-gcs/config/

echo "Entrando na pasta terraform para copiar os arquivos"
cd ./../../../site-speed-dashboard/terraform

echo "Iniciando copia para GCP"
gsutil cp -r ./files-copy-to-gcs/* "gs://$2"

echo "Excluindo zips"
cd ./files-copy-to-gcs/config
rm -rf *.zip

if [ "$1" != "local" ]; then
    echo "Excluindo projeto baixado"
    cd ../../../../
    rm -r site-speed-dashboard-"$1"
fi
echo "FIM script $0"