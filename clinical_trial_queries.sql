-- Insert vendors
INSERT INTO vendors (vendor_name, id_format) VALUES
('MedRecruit', 'numeric'),
('ClinSource', 'alphanumeric');

-- Insert clinical sites
INSERT INTO sites (site_name, location, coordinator_name) VALUES
('Houston Medical Center', 'Houston, TX', 'Ana Rivera'),
('Dallas Research Institute', 'Dallas, TX', 'James Patel'),
('Austin Clinical Partners', 'Austin, TX', 'Maria Lopez'),
('San Antonio Health Group', 'San Antonio, TX', 'David Kim'),
('Memorial Research Site', 'Houston, TX', 'Sarah Chen');

-- Insert facilities
INSERT INTO facilities (facility_name, location, contact_info) VALUES
('St. Luke Hospital', 'Houston, TX', 'records@stluke.com'),
('Texas General Hospital', 'Dallas, TX', 'medrecords@txgeneral.com'),
('Austin Regional Clinic', 'Austin, TX', 'roi@austinclinic.com'),
('Methodist Hospital', 'San Antonio, TX', 'records@methodist.com'),
('Memorial Hermann', 'Houston, TX', 'roi@memorialhermann.com');

-- Insert patients
INSERT INTO patients (vendor_patient_id, vendor_id, site_id) VALUES
('10001', 1, 1),
('10002', 1, 1),
('10003', 1, 2),
('AB-204', 2, 2),
('AB-205', 2, 3),
('AB-206', 2, 3),
('10007', 1, 4),
('AB-208', 2, 4),
('10009', 1, 5),
('AB-210', 2, 5);

-- Insert recruitment tracking
INSERT INTO recruitment_tracking 
(patient_id, first_contact_date, roi_sent_date, followup_1_date, followup_2_date, roi_signed_date, status) VALUES
(1, '2023-01-05', '2023-01-10', '2023-01-17', NULL, '2023-01-20', 'roi signed'),
(2, '2023-01-06', '2023-01-11', '2023-01-18', '2023-01-25', NULL, 'lost'),
(3, '2023-01-08', '2023-01-13', '2023-01-20', NULL, '2023-01-28', 'roi signed'),
(4, '2023-01-09', '2023-01-14', '2023-01-21', '2023-01-28', '2023-02-01', 'roi signed'),
(5, '2023-01-10', '2023-01-15', '2023-01-22', NULL, NULL, 'pending'),
(6, '2023-01-11', '2023-01-16', '2023-01-23', '2023-01-30', '2023-02-05', 'roi signed'),
(7, '2023-01-12', '2023-01-17', '2023-01-24', NULL, '2023-02-01', 'roi signed'),
(8, '2023-01-13', '2023-01-18', '2023-01-25', '2023-02-01', NULL, 'lost'),
(9, '2023-01-14', '2023-01-19', '2023-01-26', NULL, '2023-02-03', 'roi signed'),
(10, '2023-01-15', '2023-01-20', '2023-01-27', NULL, '2023-02-06', 'roi signed');

-- Insert record requests
INSERT INTO record_requests 
(patient_id, facility_id, roi_sent_date, followup_1_date, followup_2_date, records_received_date, status) VALUES
(1, 1, '2023-01-22', '2023-01-29', NULL, '2023-02-05', 'received'),
(3, 2, '2023-01-30', '2023-02-06', '2023-02-13', '2023-03-01', 'received'),
(4, 3, '2023-02-03', '2023-02-10', NULL, '2023-02-20', 'received'),
(6, 1, '2023-02-07', '2023-02-14', '2023-02-21', '2023-03-10', 'received'),
(7, 4, '2023-02-03', '2023-02-10', NULL, '2023-02-18', 'received'),
(9, 5, '2023-02-05', '2023-02-12', NULL, '2023-02-19', 'received'),
(10, 2, '2023-02-08', '2023-02-15', '2023-02-22', NULL, 'pending');

SELECT v.vendor_name, COUNT(p.patient_id) AS total_patients
FROM patients p
JOIN vendors v ON p.vendor_id = v.vendor_id
GROUP BY v.vendor_name;

SELECT v.vendor_name,
COUNT(p.patient_id) AS total_referred,
SUM(CASE WHEN rt.status='roi signed' THEN 1 ELSE 0 END) AS roi_signed_patients,
ROUND(SUM(CASE WHEN rt.status='roi signed' THEN 1 ELSE 0 END) * 100.0/COUNT(p.patient_id), 1) 
AS roi_rate_pct
FROM vendors v
JOIN patients p ON v.vendor_id = p.vendor_id
JOIN recruitment_tracking rt ON p.patient_id = rt.patient_id
GROUP BY v.vendor_name;

SELECT v.vendor_name,
COUNT (p.patient_id) AS total_patients_referred,
COUNT (CASE WHEN rt.roi_signed_date IS NOT NULL THEN 1 END) AS total_patients_roi_signed,
ROUND(AVG(CASE WHEN rt.roi_signed_date IS NOT NULL THEN rt.roi_signed_date - rt.first_contact_date END), 1) AS avg_days_to_sign_roi
FROM vendors v
JOIN patients p ON p.vendor_id = v.vendor_id
JOIN recruitment_tracking rt ON rt.patient_id = p.patient_id
GROUP BY v.vendor_name;

SELECT f.facility_name,
ROUND(AVG(rr.records_received_date - rr.roi_sent_date), 1) AS avg_turnaround_time, 
COUNT(rr.request_id) AS total_requests, 
COUNT(CASE WHEN rr.status = 'pending' THEN 1 END) AS pending_requests
FROM facilities f
JOIN record_requests rr ON rr.facility_id = f.facility_id
GROUP BY f.facility_name
ORDER BY avg_turnaround_time DESC;

SELECT p.patient_id, v.vendor_name, s.site_name,
CASE 
WHEN rt.roi_signed_date IS NOT NULL 
THEN 'Yes' ELSE 'No' END AS roi_signed,
CASE 
WHEN rr.records_received_date IS NOT NULL 
THEN 'Yes' ELSE 'No' 
END AS records_received
FROM patients p
JOIN vendors v ON v.vendor_id = p.vendor_id
JOIN sites s ON s.site_id = p.site_id 
LEFT JOIN recruitment_tracking rt ON rt.patient_id = p.patient_id
LEFT JOIN record_requests rr ON rr.patient_id = p.patient_id;

SELECT p.patient_id, v.vendor_name, s.site_name,
CASE
WHEN rt.roi_signed_date IS NOT NULL
THEN 'Yes' ELSE 'No' END
AS roi_signed,
CASE
WHEN rr.records_received_date IS NOT NULL
THEN 'Yes' ELSE 'No' END 
AS records_received
FROM patients p
JOIN vendors v ON v.vendor_id = p.vendor_id
JOIN sites s ON s.site_id = p.site_id
LEFT JOIN recruitment_tracking rt ON rt.patient_id = p.patient_id
LEFT JOIN record_requests rr ON rr.patient_id = p.patient_id
WHERE rt.roi_signed_date IS NOT NULL
AND rr.records_received_date IS NULL;

SELECT v.vendor_name,
COUNT (p.patient_id) AS total_patients_referred,
SUM(CASE WHEN rt.roi_signed_date IS NOT NULL THEN 1 ELSE 0 END) 
AS total_rois_signed,
SUM(CASE WHEN rr.records_received_date IS NOT NULL THEN 1 ELSE 0 END) 
AS total_records_received,
ROUND(SUM(CASE WHEN rt.roi_signed_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0/ COUNT (p.patient_id), 1) 
AS roi_rate_pct,
ROUND(SUM(CASE WHEN rr.records_received_date IS NOT NULL THEN 1 ELSE 0 END) * 100.0/ COUNT (p.patient_id),1) 
AS records_received_rate_pct
FROM vendors v
JOIN patients p ON p.vendor_id = v.vendor_id
LEFT JOIN  recruitment_tracking rt ON rt.patient_id = p.patient_id
LEFT JOIN record_requests rr ON rr.patient_id = p.patient_id
GROUP BY v.vendor_name
ORDER BY total_patients_referred DESC
