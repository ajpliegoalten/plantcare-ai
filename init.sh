#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
echo "Repositorio: $(pwd)"
echo "Estado: pre-bootstrap; todavía no existe proyecto Xcode ni aplicación verificable."
echo "Siguiente paso: primera funcionalidad lista en feature_list.json (bootstrap iOS)."
echo "Tras el bootstrap, documentar aquí los comandos reales de compilación, pruebas y ejecución con xcodebuild y un destino disponible."
