# 🛒 Olist E-Commerce EDA — Brazil

## 📌 Project Overview
Exploratory data analysis of **100k+ orders** from Olist, Brazil's largest 
e-commerce platform, to identify key drivers of customer satisfaction.

## 🔍 Key Findings

| Insight | Finding |
|---------|---------|
| Delivery delay impact | Deliveries beyond 20 days saw a **20% drop** in review scores |
| Freight burden | 18% reduction in freight ratio correlated with **10% increase** in reviews |
| Geographic concentration | São Paulo accounted for **37%+** of total revenue |
| Seller performance | Amazonas sellers showed the **highest delay rates** |

## 🛠️ Tech Stack
`PostgreSQL` `SQL` `DBeaver` `Python` `Pandas` `Tableau`

## 🗄️ Database Schema
9 relational tables integrated into a unified analytical schema:

`customers` · `orders` · `order_items` · `products` · `sellers` · 
`order_payments` · `order_reviews` · `product_category_translation` · `geolocation`

## ⚡ Highlights
- **Real-world data quality fix:** Free-text review fields with embedded line breaks/quotes 
  broke standard CSV parsing — resolved using a custom Pandas ingestion pipeline
- **Indexed analytical view** (`analytics_view`) built for efficient querying across 100k+ rows
- **Structured EDA** across 4 domains: sales trends, customer behavior, logistics, and seller performance

## 📊 Dashboard
🔗 *Tableau dashboard coming soon*

## 📁 File Structure
| File | Description |
|------|-------------|
| `01_data_ingestion_load_reviews.py` | Custom Pandas pipeline for malformed CSV ingestion |
| `02_eda_analysis.sql` | Full EDA script — schema, data prep, and analysis |

## 📂 Dataset
Source: [Olist Dataset on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
