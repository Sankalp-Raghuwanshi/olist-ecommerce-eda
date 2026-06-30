# Olist E-Commerce EDA — Brazil

## Project Overview
Exploratory data analysis of 100k+ orders from Olist, 
Brazil's largest e-commerce platform, to identify key 
drivers of customer satisfaction.

## Key Findings
- Deliveries beyond 20 days saw a 20% drop in average review scores
- An 18% reduction in freight-to-price ratio correlated with 
  a 10% increase in customer reviews
- São Paulo accounted for 37%+ of total revenue
- Sellers from Amazonas state showed the highest delay rates

## Tech Stack
PostgreSQL · SQL · DBeaver · Python (Pandas) · Tableau

## Database Schema
9 tables integrated into a unified analytical schema:
customers, orders, order_items, products, sellers, 
order_payments, order_reviews, product_category_translation, 
geolocation

## Highlights
- Resolved real-world data quality issue: free-text review 
  fields with embedded line breaks/quotes broke standard CSV 
  parsing — fixed using a custom Pandas ingestion pipeline
- Built indexed analytical view (analytics_view) for 
  efficient querying across 100k+ rows
- Structured EDA across 4 domains: sales trends, 
  customer behavior, logistics, and seller performance

## Dashboard
[View live Tableau dashboard here] ← add link tomorrow

## Dataset
Source: [Olist Dataset on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
