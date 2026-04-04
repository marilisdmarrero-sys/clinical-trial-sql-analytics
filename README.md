# A Workflow and Data Analysis of Clinical Trial Recruitment Efficiency 
> Based on real clinical operations experience managing a two-phase patient tracking system across 10-15 clinical trial sites.

---

## Project Background

This project was not an academic exercise. It was built from direct clinical operations experience managing a two-phase patient tracking system across 10-15 clinical trial sites. The data model, business questions, and analysis were driven by patterns observed firsthand during trial operations as a Health Information Specialist.

The database structure and analysis were driven by clinical operations expertise, not just technical convention. Domain knowledge shaped every data modeling decision.

---

## Database Design

The patient pipeline has two distinct phases, each requiring separate tracking:

- **Phase 1** – Recruitment and signed ROI
- **Phase 2** – Medical record retrieval

Combining phases into the same table would create data integrity issues and obscure the pipeline analysis.

---

## Query 1 – Vendor Referral Volume

**Business question:** Which vendor is sending more patients?

Before analyzing patient timelines, I first wanted to understand recruitment source distribution. Vendor volume directly impacts budget allocation decisions, so identifying which vendor was delivering more patients was a necessary first step in the analysis.

```sql
SELECT v.vendor_name, COUNT(p.patient_id) AS total_patients
FROM patients p
JOIN vendors v ON p.vendor_id = v.vendor_id
GROUP BY v.vendor_name;
```

**Results:** Both vendors referred equal volume – 5 patients each. Volume alone suggested no difference between vendors, making a deeper quality analysis necessary.

---

## Query 2 – Vendor ROI Rate

**Business question:** Which vendor has the highest ROI signature rate among referred patients?

Vendor volume alone doesn't tell the full story. I needed to understand not just how many patients each vendor referred, but how many of those patients actually moved forward and signed a ROI form. This measures vendor quality, not just quantity, and directly informs decisions about which vendor relationships are worth investing in for future trials.

```sql
SELECT 
  v.vendor_name,
  COUNT(p.patient_id) AS total_referred,
  SUM(CASE WHEN rt.status = 'roi_signed' THEN 1 ELSE 0 END) AS roi_signed_patients,
  ROUND(SUM(CASE WHEN rt.status = 'roi_signed' THEN 1 ELSE 0 END) * 100.0 / COUNT(p.patient_id), 1) AS roi_rate_pct
FROM vendors v
JOIN patients p ON v.vendor_id = p.vendor_id
JOIN recruitment_tracking rt ON p.patient_id = rt.patient_id
GROUP BY v.vendor_name;
```

**Results:** Despite equal referral volume, vendors showed meaningfully different signed ROI rates. MedRecruit converted 80% of referred patients while ClinSource converted 60%. This suggests MedRecruit is better at pre-screening patients before referral, making them the higher quality vendor despite identical volume.

---

## Query 3 – Vendor Referral Quality

**Business question:** Are both vendors delivering equal value, or is one vendor referring higher quality, better pre-screened patients who convert faster? And how does the speed of signed ROI forms differ between vendors?

Beyond volume and ROI rates, I wanted to understand how efficiently each vendor's patients moved through the process. Speed to sign the ROI impacts staff workload and overall trial timeline. A vendor whose patients take longer to sign requires more follow-up resources, increasing operational costs even if they eventually consent.

```sql
SELECT 
  v.vendor_name,
  COUNT(p.patient_id) AS total_patients_referred,
  SUM(CASE WHEN rt.roi_signed_date IS NOT NULL THEN 1 ELSE 0 END) AS total_patients_roi_signed,
  ROUND(AVG(CASE WHEN rt.roi_signed_date IS NOT NULL 
    THEN rt.roi_signed_date - rt.first_contact_date END), 1) AS avg_days_to_sign_roi
FROM vendors v
JOIN patients p ON p.vendor_id = v.vendor_id
JOIN recruitment_tracking rt ON rt.patient_id = p.patient_id
GROUP BY v.vendor_name;
```

**Results:** MedRecruit outperformed ClinSource on both quality and speed. MedRecruit converted 80% of referred patients in an average of 18.8 days versus ClinSource's 60% conversion rate and 23.3 day average. This suggests MedRecruit refers better pre-screened candidates who require less follow-up before signing ROI authorization. Budget recommendation: increase allocation toward MedRecruit.

---

## Query 4 – Record Retrieval Turnaround Time

**Business question:** Which medical facilities have the longest turnaround times for releasing records, and are there any outstanding requests that could be blocking trial progress?

Delayed medical record retrieval directly impacts patient eligibility timelines and overall trial schedule. Identifying slow facilities early allows the recruitment team to prioritize follow-up outreach and flag potential bottlenecks before they affect the trial.

```sql
SELECT 
  f.facility_name,
  ROUND(AVG(rr.records_received_date - rr.roi_sent_date), 1) AS avg_turnaround_time,
  COUNT(rr.request_id) AS total_requests,
  COUNT(CASE WHEN rr.status = 'pending' THEN 1 END) AS pending_requests
FROM facilities f
JOIN record_requests rr ON rr.facility_id = f.facility_id
GROUP BY f.facility_name
ORDER BY avg_turnaround_time DESC;
```

**Results:** Facility turnaround times ranged from 14 days at Memorial Hermann to 30 days at Texas General Hospital, a 16 day difference that represents significant operational risk at scale. Texas General Hospital was also the only facility with an outstanding pending request, suggesting a consistent pattern of delayed response. This analysis would directly inform outreach prioritization — high turnaround facilities would receive earlier and more frequent follow-up to protect trial timelines.

---

## Query 5 – Patient Pipeline Overview

**Business question:** What does each patient's complete journey look like – who referred them, which site did they belong to, did they sign the ROI, and were their records received?

A patient-level view allows operations managers to quickly identify where individual patients are in the pipeline, spot patterns by vendor or site, and flag patients who signed the ROI but never had records received – a potential bottleneck that could delay trial progress.

```sql
SELECT 
  p.patient_id, 
  v.vendor_name, 
  s.site_name,
  CASE WHEN rt.roi_signed_date IS NOT NULL THEN 'Yes' ELSE 'No' END AS roi_signed,
  CASE WHEN rr.records_received_date IS NOT NULL THEN 'Yes' ELSE 'No' END AS records_received
FROM patients p
JOIN vendors v ON v.vendor_id = p.vendor_id
JOIN sites s ON s.site_id = p.site_id
LEFT JOIN recruitment_tracking rt ON rt.patient_id = p.patient_id
LEFT JOIN record_requests rr ON rr.patient_id = p.patient_id;
```

**Results:** The query produced a complete patient journey matrix across all pipeline phases. This single view replaced the need to manually cross reference multiple Excel tabs – combining vendor source, site assignment, ROI status and records receipt into one unified report. Out of 10 patients, 8 signed the ROI and 6 had records successfully retrieved, revealing a 25% drop off between ROI signature and records received that would not have been visible without connecting both pipeline phases.

---

## Query 6 – Active Cases Requiring Follow Up

**Business question:** Which patients have authorized medical record release but whose records have not yet been received? These are active cases requiring immediate follow-up.

In a clinical trial, every day a patient sits in the pipeline without their records being received is a potential delay to their eligibility assessment and overall trial timeline. This query functions as a real time operational report – run regularly to identify which patients need outreach priority and which facilities are causing it.

```sql
SELECT 
  p.patient_id, 
  v.vendor_name, 
  s.site_name,
  CASE WHEN rt.roi_signed_date IS NOT NULL THEN 'Yes' ELSE 'No' END AS roi_signed,
  CASE WHEN rr.records_received_date IS NOT NULL THEN 'Yes' ELSE 'No' END AS records_received
FROM patients p
JOIN vendors v ON v.vendor_id = p.vendor_id
JOIN sites s ON s.site_id = p.site_id
LEFT JOIN recruitment_tracking rt ON rt.patient_id = p.patient_id
LEFT JOIN record_requests rr ON rr.patient_id = p.patient_id
WHERE rt.roi_signed_date IS NOT NULL
AND rr.records_received_date IS NULL;
```

**Results:** One patient was identified as pending – linked to Texas General Hospital, the same facility flagged earlier as having the longest average turnaround time of 30 days. This cross-query confirms Texas General Hospital as a consistent bottleneck in the medical records pipeline and would trigger escalated outreach in a real trial setting.

---

## Query 7 – Vendor Full Pipeline Analysis

**Business question:** Of all patients referred by each vendor, what percentage successfully signed the ROI and ultimately had their medical records received? This measures vendor effectiveness across the full operational pipeline, not just initial referral volume.

```sql
SELECT 
  v.vendor_name,
  COUNT(p.patient_id) AS total_patients_referred,
  SUM(CASE WHEN rt.roi_signed_date IS NOT NULL THEN 1 ELSE 0 END) AS total_rois_signed,
  SUM(CASE WHEN rr.records_received_date IS NOT NULL THEN 1 ELSE 0 END) AS total_records_received,
  ROUND(SUM(CASE WHEN rt.roi_signed_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(p.patient_id), 1) AS roi_rate_pct,
  ROUND(SUM(CASE WHEN rr.records_received_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(p.patient_id), 1) AS records_received_rate_pct
FROM vendors v
JOIN patients p ON p.vendor_id = v.vendor_id
LEFT JOIN recruitment_tracking rt ON rt.patient_id = p.patient_id
LEFT JOIN record_requests rr ON rr.patient_id = p.patient_id
GROUP BY v.vendor_name
ORDER BY total_patients_referred DESC;
```

**Results:** Despite equal referral volume, MedRecruit significantly outperformed ClinSource at every pipeline stage. MedRecruit converted 80% of referrals to ROI signatures and maintained that rate through records receipt. ClinSource converted 60% to ROI signatures and dropped further to 40% records received – meaning 3 out of 5 referred patients never completed the records pipeline.

**Budget recommendation:** Reallocate recruitment spend toward MedRecruit and initiate a performance review with ClinSource.

---

## Key Takeaways

- Vendor volume is not a reliable quality metric — equal referral numbers masked significant performance differences.
- Facility turnaround time and vendor pipeline rates are leading indicators of trial efficiency.
- A relational database approach replaced manual cross-referencing across multiple Excel tabs, enabling pattern recognition that would not have been visible otherwise.
- Domain knowledge was essential — clinical operations expertise shaped every data modeling decision, from pipeline phase separation to terminology accuracy around ROI authorization versus trial consent.

---

## Tools Used
- PostgreSQL v15
- DB Fiddle

## Live Database
[View the full schema and queries on DB Fiddle](https://www.db-fiddle.com/f/uvEDcwCorkGpLRbBMJjrFN/0)
