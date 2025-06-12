# 🎯 Target Brazil Operations – SQL Case Study

This project analyzes **e-commerce operations data** from Target's Brazil market using **pure SQL in BigQuery**. It explores trends in customer orders, freight logistics, payments, delivery time, and regional sales to deliver actionable insights for improving operational performance and driving expansion.

---

## 📌 Project Summary

- 🗓️ **Data Period**: 2016 – 2018  
- 📦 **Data Volume**: ~100,000 records  
- 🔍 **Goal**: Analyze business metrics and customer behavior to optimize sales, logistics, and payment strategy in Brazil.

---

## 🧠 Key Business Questions Answered

1. Are customer orders growing year-over-year?
2. When during the day/week/month do people mostly place orders?
3. Which states have the highest order volume, freight value, and delays?
4. What is the percentage increase in order payments from 2017 to 2018?
5. How accurate are delivery timelines vs. estimated delivery dates?
6. Which payment methods and installment options are most used?

---

## 📊 Dataset Description

The dataset includes 100,000+ records spread across:

| Table Name     | Description                                  |
|----------------|----------------------------------------------|
| `orders`       | Purchase, delivery, and estimated delivery timestamps |
| `customers`    | Customer location and ID info                |
| `order_items`  | Freight and item price values                |
| `payments`     | Payment type, value, and installments        |

> 🗂 **Note**: Data is sourced from the Scaler DSML program. It is not uploaded here due to licensing and privacy concerns. Sample data structure can be found [here](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

---

## 🧪 SQL Techniques Used

- Joins across multiple tables
- Window functions: `ROW_NUMBER()`, `LAG()`, `AVG() OVER()`
- CTEs (Common Table Expressions)
- Aggregations: `SUM()`, `COUNT()`, `AVG()`
- Date functions: `EXTRACT()`, `DATETIME_DIFF()`
- Grouping and filtering

---

## 📈 Key Insights

- 📈 Orders peaked in **May** and **September**
- ☀️ Most orders were placed in the **afternoon (13–18 hrs)**
- 📍 State **SP** dominated in total sales and freight cost
- 💸 **PB** had the **highest average order value**
- 🚚 Delivery delays averaged **4–6 days** in some states
- 💳 Payment volume increased by **140%** from 2017 to 2018 (Jan–Aug)

---


## 👨‍💻 Author

**Srisailam Jeripothula**  
Data Analyst | SQL + Python | AI/ML Enthusiast  
📧 [LinkedIn](https://www.linkedin.com/in/srisailamjeripothula)

---

## 🏁 Conclusion

Target has strong performance in select Brazilian states, but significant growth opportunities exist in underperforming regions. Strategic efforts in freight optimization, delivery prediction, and localized marketing could help scale operations effectively.
