-- Vendors who referred patients
CREATE TABLE vendors (
  vendor_id SERIAL PRIMARY KEY,
  vendor_name VARCHAR(100),
  id_format VARCHAR(50) -- e.g. 'numeric' or 'alphanumeric'
);

-- Clinical trial sites
CREATE TABLE sites (
  site_id SERIAL PRIMARY KEY,
  site_name VARCHAR(100),
  location VARCHAR(100),
  coordinator_name VARCHAR(100)
);

-- Medical facilities where records are requested from
CREATE TABLE facilities (
  facility_id SERIAL PRIMARY KEY,
  facility_name VARCHAR(100),
  location VARCHAR(100),
  contact_info VARCHAR(100)
);

-- Patients
CREATE TABLE patients (
  patient_id SERIAL PRIMARY KEY,
  vendor_patient_id VARCHAR(50), -- original ID from vendor
  vendor_id INT REFERENCES vendors(vendor_id),
  site_id INT REFERENCES sites(site_id)
);

-- Phase 1: Recruitment pipeline
CREATE TABLE recruitment_tracking (
  recruitment_id SERIAL PRIMARY KEY,
  patient_id INT REFERENCES patients(patient_id),
  first_contact_date DATE,
  roi_sent_date DATE,
  followup_1_date DATE,
  followup_2_date DATE,
  followup_3_date DATE,
  roi_signed_date DATE,
  status VARCHAR(50) -- e.g. 'roi signed', 'lost', 'pending'
);

-- Phase 2: Medical records pipeline
CREATE TABLE record_requests (
  request_id SERIAL PRIMARY KEY,
  patient_id INT REFERENCES patients(patient_id),
  facility_id INT REFERENCES facilities(facility_id),
  roi_sent_date DATE,
  followup_1_date DATE,
  followup_2_date DATE,
  records_received_date DATE,
  status VARCHAR(50) -- e.g. 'received', 'pending', 'unresponsive'
);
