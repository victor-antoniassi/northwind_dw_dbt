# Northwind Analytics Engineering Project

Projeto de análise de dados desenvolvido para a Northwind Traders, uma empresa fictícia de varejo com faturamento mensal de 1.5M, utilizando práticas modernas de Analytics Engineering.

## Objetivos do Projeto

Análise focada em dois desafios estratégicos:
- Aumento do ticket médio
- Redução do churn de clientes

## Stack Técnica

- **Armazenamento**: DuckDB
- **Transformação**: dbt (data build tool)
- **Análise**: Python, Pandas, Seaborn
- **Versionamento**: Git

## Estrutura do Projeto

```
├── models/                    # Modelos dbt
│   ├── stg/                  # Stage models - Padronização inicial
│   └── dw/                   # Data Warehouse models - Modelo dimensional
├── raw/                      # Arquivos fonte CSV
├── report.ipynb             # Notebook do relatório final
├── dbt_project.yml          # Configurações dbt
├── packages.yml             # Dependências dbt
└── requirements.txt         # Dependências Python
```

## Arquitetura de Dados

### Staging (stg)
- Padronização inicial dos dados
- Conversão e validação de tipos
- Preparação para modelagem dimensional

### Data Warehouse (dw)
- **Dimensões**: customers, products, employees, dates, geography
- **Fatos**: orders, order_details
