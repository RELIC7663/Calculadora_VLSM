# Calculadora de Subredes IP

Este proyecto permite calcular subredes a partir de una dirección IP, máscara de red y número deseado de subredes. Proporciona información detallada como las direcciones de cada subred, el número de hosts posibles y la submáscara correspondiente a cada subred.

## 🚀 Funcionalidades

- Ingreso de dirección IP, máscara de red y número de subredes.
- Validación de datos ingresados.
- Generación automática de:
  - Subredes posibles.
  - Rango de direcciones IP por subred.
  - Número de hosts por subred.
  - Submáscara por subred.
- Interfaz intuitiva con botones dinámicos para cada subred generada.
- Validación automática de si es posible generar la cantidad de subredes solicitada.

## 🖼️ Capturas

![Interfaz del proyecto](https://github.com/user-attachments/assets/f94eab90-2cba-4eb2-a490-0bba058b89e1)


## 🧠 Lógica aplicada

- Se identifican los bits disponibles para subneteo.
- Se verifica si es posible generar la cantidad de subredes solicitadas.
- Se recalcula la nueva submáscara.
- Se obtienen las direcciones IP para cada subred.

## 📦 Instalación y ejecución local

1. Clona el repositorio:

```bash
git clone [https://github.com/usuario/tu-repo-subredes.git](https://github.com/RELIC7663/Calculadora_VLSM.git)
