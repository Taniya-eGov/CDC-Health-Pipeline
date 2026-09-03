"""
Per-table generation rules for the health-campaign test data scripts.

Everything table-specific lives here; generate_records.py and update_records.py
are generic engines that read this module. Adding a table means adding one entry.

Shapes are taken from real rows in postgres/reference_data.sql, not invented:

    household            H-2023-09-26-000017        household_member     uuid
    project_task         PT-2023-11-03-000008       project              uuid
    project_beneficiary  PTB-2023-11-07-000276      task_resource        uuid
    project_staff        PTS-2023-12-14-000010      address              uuid
    project_facility     PF-2023-10-11-000001       project_target       uuid
    facility             F-2023-09-14-000001        project_address      uuid
    product              P-2023-09-14-000003        individual           uuid
    product_variant      PVAR-2023-10-10-000001     stock                uuid *
                                                    stock_reconciliation uuid *

    * stock returned no rows, so its id shape is a guess. Everything else is
      copied from a real row.

Foreign keys carry those same business ids -- task_resource.taskid holds
"PT-2023-10-13-000001", product_variant.productid holds "P-2023-10-10-000004" --
so children sample real parent ids rather than inventing uuids.
"""

import random
import uuid

# Tenants seen in the reference data.
TENANTS = ["mz", "pg.citya"]


# -- Id formats ---------------------------------------------------------------
#
# None  -> uuid4
# "PT"  -> PT-YYYY-MM-DD-NNNNNN, the counter continuing per day from what the
#          table already holds, so re-running never collides on the primary key.

ID_PREFIX = {
    "household": "H",
    "project_task": "PT",
    "project_beneficiary": "PTB",
    "project_staff": "PTS",
    "project_facility": "PF",
    "facility": "F",
    "product": "P",
    "product_variant": "PVAR",

    "household_member": None,
    "project": None,
    "task_resource": None,
    "address": None,
    "project_target": None,
    "project_address": None,
    "individual": None,
    "stock": None,
    "stock_reconciliation_log": None,
}

# Columns other than `id` that also carry a prefixed business id.
SECONDARY_IDS = {
    "individual": {"individualid": "IND"},
}


# -- Generation order ---------------------------------------------------------
#
# A table can only be generated once every table it references holds rows.

LEVELS = [
    ["address", "individual", "product"],
    ["project", "facility", "household", "product_variant"],
    ["project_task", "project_target", "project_address",
     "project_staff", "project_facility", "project_beneficiary",
     "stock", "stock_reconciliation_log"],
    ["task_resource"],
]

# household_member is deliberately absent. It has no primary key, no unique
# constraint and a nullable id, so PostgreSQL has no usable replica identity for
# it -- adding it to a publication makes PostgreSQL reject UPDATEs from the
# application itself. It is excluded from the connector and therefore never
# created, so generating it would fail. Restore it here once
# ALTER TABLE household_member REPLICA IDENTITY FULL has been applied.

ORDER = [t for level in LEVELS for t in level]


# -- Foreign keys -------------------------------------------------------------
#
# column -> parent table. The engine samples an existing id from the parent and
# fails loudly if the parent is empty.

FKS = {
    "household":            {"addressid": "address"},
    "household_member":     {"householdid": "household", "individualid": "individual"},
    "project":              {"addressid": "address"},
    "project_task":         {"projectid": "project", "addressid": "address",
                             "projectbeneficiaryid": "project_beneficiary"},
    "project_target":       {"projectid": "project"},
    "project_address":      {"projectid": "project"},
    "project_staff":        {"projectid": "project"},
    "project_facility":     {"projectid": "project", "facilityid": "facility"},
    "project_beneficiary":  {"projectid": "project", "beneficiaryid": "household"},
    "product_variant":      {"productid": "product"},
    "facility":             {"addressid": "address"},
    "task_resource":        {"taskid": "project_task", "productvariantid": "product_variant"},
    "stock":                {"facilityid": "facility", "productvariantid": "product_variant"},
    "stock_reconciliation_log": {"facilityid": "facility", "productvariantid": "product_variant"},
}

# project_task.projectbeneficiaryid is empty in the reference row (only the
# client reference is set), and project_beneficiary is generated in the same
# level, so it is left NULL rather than forcing an ordering dependency.
OPTIONAL_FKS = {("project_task", "projectbeneficiaryid")}


# -- additionaldetails --------------------------------------------------------
#
# Most tables carry the eGov AdditionalFields envelope:
#     {"fields": [{"key": k, "value": v}], "schema": "...", "version": n}
# household / household_member / task_resource hold null in the reference rows,
# and project holds a free-form object instead.

ADDITIONAL_DETAILS = {
    "project_task": ("Task", [("dateOfDelivery", "epoch"), ("dateOfAdministration", "epoch"),
                              ("dateOfVerification", "epoch"), ("cycleIndex", "01"),
                              ("doseIndex", "01"), ("deliveryStrategy", "DIRECT")]),
    "project_beneficiary": ("registration", [("key1", "value1")]),
    "project_staff": ("registration", [("key", "value")]),
    "project_facility": ("test_e37466be924cjhghjg", [("test_12bc5f24692f", "test_bf376bce4c01")]),
    "facility": ("test_e37466be924cjhghjg", [("test_12bc5f24692f", "test_bf376bce4c01")]),
    "product": ("test_3e1c7976b4d6", [("form", "tablet")]),
    "product_variant": ("test", [("weight", "5g")]),
    "individual": (None, [("FUNCTIONAL_ROLE_1", "SANITATION_HELPER"),
                          ("EMPLOYMENT_TYPE_1", "FIXED"), ("EMPLOYER", "ULB")]),
    "stock": ("Stock", [("note", "generated")]),
    "stock_reconciliation_log": ("StockReconciliation", [("note", "generated")]),
    # null in the reference rows
    "household": None,
    "household_member": None,
    "task_resource": None,
    "project_target": None,
    "address": None,
    "project_address": None,
    # project uses a free-form object, handled in VALUES below
    "project": None,
}


# -- Business column values ---------------------------------------------------
#
# Only columns that need a table-specific value. Audit columns, tenantid,
# clientreferenceid, rowversion, isdeleted and additionaldetails are handled by
# the engine for every table.
#
# Each entry is a callable taking (rnd) and returning the value.

FACILITY_NAMES = ["Facility MDA-LF-Nairobi", "Warehouse Central", "Health Post A",
                  "District Store", "Community Centre"]
PRODUCTS = [("DRUG", "Ivermectin", "Cipla"), ("DRUG", "Albendazole", "GSK"),
            ("DRUG", "Praziquantel", "Merck"), ("BEDNET", "PermaNet 3.0", "Vestergaard")]
GENDERS = ["MALE", "FEMALE", "OTHER"]
TASK_STATUS = ["DELIVERED", "NOT_ADMINISTERED", "BENEFICIARY_REFUSED", "CLOSED_HOUSEHOLD"]
TXN_TYPE = ["RECEIVED", "DISPATCHED"]
TXN_REASON = ["RECEIVED", "RETURNED", "DAMAGED", "LOST"]
PARTY_TYPE = ["WAREHOUSE", "STAFF"]

VALUES = {
    "address": {
        "doorno": lambda r: str(r.randint(1, 999)),
        "latitude": lambda r: round(r.uniform(-25.0, -10.0), 6),
        "longitude": lambda r: round(r.uniform(30.0, 41.0), 6),
        "locationaccuracy": lambda r: r.randint(5, 100),
        "type": lambda r: r.choice(["PERMANENT", "CORRESPONDENCE", "OTHER"]),
        "addressline1": lambda r: f"Address Line {r.randint(1, 99)}",
        "addressline2": lambda r: f"Area {r.randint(1, 20)}",
        "landmark": lambda r: r.choice(["Near School", "Near Clinic", "Market", "Bus Stop"]),
        "city": lambda r: r.choice(["Cuamba", "Mopeia", "Nampula", "Quelimane"]),
        "pincode": lambda r: str(r.randint(100000, 999999)),
        "buildingname": lambda r: f"Building {r.randint(1, 50)}",
        "street": lambda r: r.choice(["MG road", "Main Street", "Church Road"]),
        "localitycode": lambda r: f"SUN{r.randint(1, 40):02d}",
        "wardcode": lambda r: f"B{r.randint(1, 9)}",
    },
    "project": {
        "projectnumber": lambda r: f"PJ/2023-24/{r.randint(1,12):02d}/{r.randint(1,999999):06d}",
        "name": lambda r: r.choice(["MDA Campaign", "SMC Round", "Bednet Distribution"]),
        "projecttype": lambda r: r.choice(["CPS-CWS", "MDA", "LLIN"]),
        "projectsubtype": lambda r: r.choice(["ROUND-1", "ROUND-2"]),
        "department": lambda r: "Health",
        "description": lambda r: "Campaign project",
        "referenceid": lambda r: f"CMP-{r.randint(1000, 9999)}",
        "natureofwork": lambda r: r.choice(["FIELD", "OFFICE"]),
        "startdate": lambda r: 1684755990235 + r.randint(0, 10_000_000),
        "enddate": lambda r: 1699009849970 + r.randint(0, 10_000_000),
        "istaskenabled": lambda r: r.random() < 0.8,
        "projecthierarchy": lambda r: "",
        "additionaldetails": lambda r: {
            "creator": r.choice(["Jagankumar", "Anita", "Rui"]),
            "locality": f"SUN{r.randint(1, 40):02d}",
            "dateOfProposal": 1684780199000,
            "targetDemography": r.choice(["SM", "PW", "CH"]),
            "estimatedCostInRs": "",
        },
    },
    "project_target": {
        "beneficiarytype": lambda r: r.choice(["HOUSEHOLD", "INDIVIDUAL"]),
        "totalno": lambda r: r.randint(100, 5000),
        "targetno": lambda r: r.randint(50, 4000),
    },
    "project_address": {
        "doorno": lambda r: str(r.randint(1, 999)),
        "latitude": lambda r: round(r.uniform(-25.0, -10.0), 6),
        "longitude": lambda r: round(r.uniform(30.0, 41.0), 6),
        "locationaccuracy": lambda r: r.randint(5, 10000),
        "type": lambda r: r.choice(["PERMANENT", "OTHER"]),
        "addressline1": lambda r: "Address Line 1",
        "addressline2": lambda r: "Address Line 2",
        "landmark": lambda r: f"Area{r.randint(1, 9)}",
        "city": lambda r: f"City{r.randint(1, 9)}",
        "pincode": lambda r: str(r.randint(100000, 999999)),
        "buildingname": lambda r: "Test_Building",
        "street": lambda r: "Test_Street",
        "boundary": lambda r: f"B{r.randint(1, 9)}",
        "boundarytype": lambda r: r.choice(["Ward", "Locality", "Village"]),
    },
    "household": {
        "numberofmembers": lambda r: r.randint(1, 12),
        "householdtype": lambda r: "FAMILY",
    },
    "household_member": {
        "isheadofhousehold": lambda r: r.random() < 0.3,
    },
    "individual": {
        "userid": lambda r: str(r.randint(10000, 99999)),
        "givenname": lambda r: r.choice(["Hariprasad", "Anita", "Joao", "Maria", "Rui"]),
        "familyname": lambda r: r.choice(["Silva", "Santos", "Machava", "Cossa"]),
        "dateofbirth": "date",           # engine emits a datetime.date
        "gender": lambda r: r.choice(GENDERS),
        "bloodgroup": lambda r: r.choice(["A+", "B+", "O+", "AB+"]),
        "mobilenumber": lambda r: str(r.randint(7000000000, 9999999999)),
        "type": lambda r: r.choice(["CITIZEN", "EMPLOYEE"]),
        "username": lambda r: str(r.randint(7000000000, 9999999999)),
        "issystemuser": lambda r: r.random() < 0.5,
        "issystemuseractive": lambda r: r.random() < 0.9,
        "photo": lambda r: str(uuid.uuid4()),
        "useruuid": lambda r: str(uuid.uuid4()),
        "roles": lambda r: [{"code": c, "name": None, "tenantId": "pg.citya",
                             "description": None}
                            for c in r.sample(["SANITATION_HELPER", "SANITATION_WORKER",
                                               "CITIZEN", "FIELD_SUPERVISOR"], 2)],
    },
    "project_task": {
        "status": lambda r: r.choice(TASK_STATUS),
        "plannedstartdate": lambda r: 1699009317447 + r.randint(0, 5_000_000),
        "plannedenddate": lambda r: 1699109317447 + r.randint(0, 5_000_000),
        "actualstartdate": lambda r: 1699009317447 + r.randint(0, 5_000_000),
        "actualenddate": lambda r: 1699109317447 + r.randint(0, 5_000_000),
    },
    "task_resource": {
        "quantity": lambda r: float(r.randint(1, 5)),
        "isdelivered": lambda r: r.random() < 0.85,
        "reasonifnotdelivered": lambda r: r.choice(
            ["Service delivery is completed", "Beneficiary absent", "Refused"]),
    },
    "project_beneficiary": {
        "dateofregistration": lambda r: 1699346171792 + r.randint(0, 5_000_000),
        "tag": lambda r: None,
    },
    "project_staff": {
        "startdate": lambda r: 1702550214071 + r.randint(0, 1_000_000),
        "enddate": lambda r: 9983874101527,
        "staffid": lambda r: str(uuid.uuid4()),
    },
    "project_facility": {},
    "facility": {
        "ispermanent": lambda r: r.random() < 0.7,
        "name": lambda r: r.choice(FACILITY_NAMES),
        "usage": lambda r: r.choice(["Storing Resource", "Health Facility", "Transit"]),
        "storagecapacity": lambda r: r.randint(50, 5000),
    },
    "product": {
        "type": lambda r: r.choice(PRODUCTS)[0],
        "name": lambda r: r.choice(PRODUCTS)[1],
        "manufacturer": lambda r: r.choice(PRODUCTS)[2],
    },
    "product_variant": {
        "sku": lambda r: f"{r.choice(PRODUCTS)[1]} {r.choice([5, 10, 20, 50])}mg",
        "variation": lambda r: f"{r.choice([5, 10, 20, 50])}mg",
    },
    "stock": {
        "quantity": lambda r: r.randint(1, 500),
        "waybillnumber": lambda r: f"WB-{r.randint(100000, 999999)}",
        "dateofentry": lambda r: 1699009317447 + r.randint(0, 5_000_000),
        "campaignnumber": lambda r: f"CMP-{r.randint(1000, 9999)}",
        "referenceidtype": lambda r: "PROJECT",
        "transactiontype": lambda r: r.choice(TXN_TYPE),
        "transactionreason": lambda r: r.choice(TXN_REASON),
        "transactingpartyid": lambda r: str(uuid.uuid4()),
        "transactingpartytype": lambda r: r.choice(PARTY_TYPE),
        "sendertype": lambda r: r.choice(PARTY_TYPE),
        "senderid": lambda r: str(uuid.uuid4()),
        "receivertype": lambda r: r.choice(PARTY_TYPE),
        "receiverid": lambda r: str(uuid.uuid4()),
    },
    "stock_reconciliation_log": {
        "dateofreconciliation": lambda r: 1699009317447 + r.randint(0, 5_000_000),
        "calculatedcount": lambda r: r.randint(0, 500),
        "physicalrecordedcount": lambda r: r.randint(0, 500),
        "commentsonreconciliation": lambda r: r.choice(
            ["Counts match", "Short by 2", "Damaged units removed"]),
        "referenceidtype": lambda r: "PROJECT",
    },
}

# stock.referenceid and stock_reconciliation_log.referenceid point at a project.
FKS["stock"]["referenceid"] = "project"
FKS["stock_reconciliation_log"]["referenceid"] = "project"


# -- What an update changes ---------------------------------------------------
#
# A SQL fragment applied on top of the engine's own version bumps
# (lastmodifiedtime, clientlastmodifiedtime, rowversion, additionaldetails),
# each of which is only applied when the column exists.

MUTATIONS = {
    "household":            "numberofmembers = numberofmembers + 1",
    "household_member":     "isheadofhousehold = NOT coalesce(isheadofhousehold, false)",
    "project":              "enddate = coalesce(enddate, 0) + 86400000",
    "project_target":       "targetno = coalesce(targetno, 0) + 10",
    "project_task":         "status = 'DELIVERED'",
    "task_resource":        "quantity = coalesce(quantity, 0) + 1",
    "project_beneficiary":  "dateofregistration = coalesce(dateofregistration, 0) + 3600000",
    "project_staff":        "enddate = coalesce(enddate, 0) + 86400000",
    "project_facility":     "tenantid = tenantid",   # no business column to move
    "individual":           "givenname = givenname || ' (upd)'",
    "facility":             "storagecapacity = coalesce(storagecapacity, 0) + 10",
    "product":              "manufacturer = manufacturer || ' Ltd'",
    "product_variant":      "variation = variation || '+'",
    "stock":                "quantity = coalesce(quantity, 0) + 1",
    "stock_reconciliation_log": "physicalrecordedcount = coalesce(physicalrecordedcount, 0) + 1",

    # No audit columns at all, so there is no version to bump. The bronze tables
    # for these two use _ingested_at as the ReplacingMergeTree version instead,
    # which makes their update path order-dependent rather than value-dependent.
    "address":              "city = city || ' (upd)'",
    "project_address":      "landmark = landmark || ' (upd)'",
}

# Tables whose bronze row is versioned by load order, not by a source column.
NO_AUDIT_COLUMNS = {"address", "project_address"}

SUPPORTED = list(ORDER)


def new_random(seed: int) -> random.Random:
    return random.Random(seed)
