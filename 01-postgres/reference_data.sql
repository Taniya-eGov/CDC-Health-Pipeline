unifieddevdb=> select * from household limit 1;
         id          | tenantid |          clientreferenceid           | numberofmembers |              addressid               | additionaldetails |    
          createdby               |            lastmodifiedby            |  createdtime  | lastmodifiedtime | rowversion | isdeleted | clientcreatedtime 
| clientlastmodifiedtime |           clientcreatedby            |         clientlastmodifiedby         
---------------------+----------+--------------------------------------+-----------------+--------------------------------------+-------------------+----
----------------------------------+--------------------------------------+---------------+------------------+------------+-----------+-------------------
+------------------------+--------------------------------------+--------------------------------------
 H-2023-09-26-000017 | mz       | 582097d0-1daa-11ed-a685-713ed13bfbd0 |               3 | 70ab01ef-e839-4828-a215-40b6c4311ba2 | null              | 24a
4254a-ebaa-4999-b01a-3bb526968285 | 24a4254a-ebaa-4999-b01a-3bb526968285 | 1695727059462 |    1695727059462 |          1 | f         |     1676518296071 
|          1676518296071 | 59c1d98d-5876-43ad-9960-396b40642232 | 59c1d98d-5876-43ad-9960-396b40642232



unifieddevdb=> select * from household_member limit 1;
                  id                  | tenantid | individualid |     individualclientreferenceid      |     householdid     |      householdclientrefere
nceid      | isheadofhousehold | additionaldetails |              createdby               |  createdtime  |            lastmodifiedby            | lastmo
difiedtime | rowversion | isdeleted | clientcreatedtime | clientlastmodifiedtime |           clientcreatedby            |         clientlastmodifiedby   
      |          clientreferenceid           
--------------------------------------+----------+--------------+--------------------------------------+---------------------+---------------------------
-----------+-------------------+-------------------+--------------------------------------+---------------+--------------------------------------+-------
-----------+------------+-----------+-------------------+------------------------+--------------------------------------+--------------------------------
------+--------------------------------------
 83617267-324e-45cc-9113-b4b9808a50ea | mz       |              | 544e07c0-7dfa-11ee-a135-6162be18e936 | H-2023-11-08-009111 | 460a24f0-7dfa-11ee-a135-61
62be18e936 | t                 | null              | 624bf45e-b977-438b-967c-4bd487245ee7 | 1699422890478 | 624bf45e-b977-438b-967c-4bd487245ee7 |    169
9422890478 |          1 | f         |     1699422461591 |          1699422461672 | 624bf45e-b977-438b-967c-4bd487245ee7 | 624bf45e-b977-438b-967c-4bd4872
45ee7 | 550e98a0-7dfa-11ee-a135-6162be18e936
(1 row)

unifieddevdb=> select * from project_task limit 1;
          id          |          clientreferenceid           | tenantid |              projectid               | projectbeneficiaryid | projectbeneficiar
yclientreferenceid  | plannedstartdate | plannedenddate | actualstartdate | actualenddate |              addressid               |                       
                                                                                                                                         additionaldetail
s                                                                                                                                                        
         |              createdby               |  createdtime  |            lastmodifiedby            | lastmodifiedtime | rowversion | isdeleted | clie
ntcreatedtime | clientlastmodifiedtime |           clientcreatedby            |         clientlastmodifiedby         | status 
----------------------+--------------------------------------+----------+--------------------------------------+----------------------+------------------
--------------------+------------------+----------------+-----------------+---------------+--------------------------------------+-----------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------
---------+--------------------------------------+---------------+--------------------------------------+------------------+------------+-----------+-----
--------------+------------------------+--------------------------------------+--------------------------------------+--------
 PT-2023-11-03-000008 | 67deb570-7a38-11ee-8f3b-374ab37e35bb | mz       | 694ff86b-8030-4546-9d56-77ed94e9139d |                      | 5af5a7b0-7a38-11e
e-8f3b-374ab37e35bb |                  |                |                 |               | f3cf1c20-7d3c-45c0-8589-42b4e64c9291 | {"fields": [{"key": "d
ateOfDelivery", "value": "1699009317447"}, {"key": "dateOfAdministration", "value": "1699009317447"}, {"key": "dateOfVerification", "value": "16990093174
47"}, {"key": "cycleIndex", "value": "01"}, {"key": "doseIndex", "value": "01"}, {"key": "deliveryStrategy", "value": "DIRECT"}], "schema": "Task", "vers
ion": 1} | 624bf45e-b977-438b-967c-4bd487245ee7 | 1699009849970 | 624bf45e-b977-438b-967c-4bd487245ee7 |    1699009849970 |          1 | f         |     
1699009317447 |          1699009317447 | 624bf45e-b977-438b-967c-4bd487245ee7 | 624bf45e-b977-438b-967c-4bd487245ee7 | 
(1 row)

unifieddevdb=> select * from task_resource limit 1;
                  id                  | tenantid |    productvariantid    |        taskid        | quantity | isdelivered |     reasonifnotdelivered     
 |              createdby               |  createdtime  |            lastmodifiedby            | lastmodifiedtime | isdeleted |          clientreferencei
d           | additionaldetails 
--------------------------------------+----------+------------------------+----------------------+----------+-------------+------------------------------
-+--------------------------------------+---------------+--------------------------------------+------------------+-----------+--------------------------
------------+-------------------
 17642663-d466-4e3b-8db0-90ebc462f63f | mz       | PVAR-2023-10-10-000001 | PT-2023-10-13-000001 |        1 | t           | Service delivery is completed
 | 24a4254a-ebaa-4999-b01a-3bb526968285 | 1697179543967 | 24a4254a-ebaa-4999-b01a-3bb526968285 |    1697179543967 | f         | da2c5f07-8801-46d4-b470-2
64d635ee3f3 | 
(1 row)

unifieddevdb=> select * from address limit 1;
                  id                  | tenantid | doorno | latitude | longitude | locationaccuracy |   type    | addressline1 | addressline2 | landmark 
|   city   | pincode | buildingname | street  | localitycode | clientreferenceid | wardcode 
--------------------------------------+----------+--------+----------+-----------+------------------+-----------+--------------+--------------+----------
+----------+---------+--------------+---------+--------------+-------------------+----------
 5053fee5-4655-4917-bb43-1b5371e84861 | pg.citya | 607    |          |           |                  | PERMANENT |              |              |          
| pg.citya |         |              | MG road | SUN11        |                   | B2
(1 row)

unifieddevdb=> select * from project limit 1;
                  id                  | tenantid | projecttypeid | addressid | startdate | enddate | istaskenabled | parent | projecthierarchy |         
                                                additionaldetails                                                          |              createdby      
         |  createdtime  |            lastmodifiedby            | lastmodifiedtime | rowversion | isdeleted |    projectnumber     | projectsubtype | pro
jecttype |   name   | department | description | referenceid | natureofwork 
--------------------------------------+----------+---------------+-----------+-----------+---------+---------------+--------+------------------+---------
---------------------------------------------------------------------------------------------------------------------------+-----------------------------
---------+---------------+--------------------------------------+------------------+------------+-----------+----------------------+----------------+----
---------+----------+------------+-------------+-------------+--------------
 d1a3a1b5-f8f0-44f0-bd2d-0e4ad5119263 | pg.citya |               |           |           |         | f             |        |                  | {"creato
r": "Jagankumar", "locality": "SUN01", "dateOfProposal": 1684780199000, "targetDemography": "SM", "estimatedCostInRs": ""} | 1b348954-c257-4d18-afac-1b19
fc3d86da | 1684755990235 | 1b348954-c257-4d18-afac-1b19fc3d86da |    1684755990235 |          0 | f         | PJ/2023-24/05/002247 |                | CPS
-CWS     | Shubhang |            | Shubhang    |             | 
(1 row)

unifieddevdb=> select * from project_target limit 1;
                  id                  |              projectid               | beneficiarytype | totalno | targetno | isdeleted |              createdby 
              |            lastmodifiedby            |  createdtime  | lastmodifiedtime 
--------------------------------------+--------------------------------------+-----------------+---------+----------+-----------+------------------------
--------------+--------------------------------------+---------------+------------------
 7b7e6310-37c8-4819-a20a-33aee6ca3300 | ec154953-219f-4d23-968e-15a15ddf0ff1 |                 |       0 |        0 |           | fcd58b2b-98b3-412c-8f01
-ec86ba4b05c4 | fcd58b2b-98b3-412c-8f01-ec86ba4b05c4 | 1682423798644 |    1682423798644
(1 row)

unifieddevdb=> select * from project_address limit 1;
                  id                  | tenantid |              projectid               | doorno | latitude | longitude | locationaccuracy | type |  addr
essline1  |  addressline2  | landmark | city  | pincode | buildingname  |   street    | boundary | boundarytype 
--------------------------------------+----------+--------------------------------------+--------+----------+-----------+------------------+------+------
----------+----------------+----------+-------+---------+---------------+-------------+----------+--------------
 b7f3ef46-e9c9-4787-ba42-a27549382c77 | pg.citya | ec154953-219f-4d23-968e-15a15ddf0ff1 | 1      |       90 |       180 |            10000 |      | Addre
ss Line 1 | Address Line 2 | Area1    | City1 | 999999  | Test_Building | Test_Street | B1       | Ward
(1 row)

unifieddevdb=> select * from project_beneficiary limit 1;
          id           | tenantid |              projectid               |            beneficiaryid             |          clientreferenceid           | 
    beneficiaryclientreferenceid     |              createdby               |            lastmodifiedby            | dateofregistration |                
                    additionaldetails                                     |  createdtime  | lastmodifiedtime | rowversion | isdeleted | clientcreatedtime
 | clientlastmodifiedtime | clientcreatedby | clientlastmodifiedby | tag 
-----------------------+----------+--------------------------------------+--------------------------------------+--------------------------------------+-
-------------------------------------+--------------------------------------+--------------------------------------+--------------------+----------------
--------------------------------------------------------------------------+---------------+------------------+------------+-----------+------------------
-+------------------------+-----------------+----------------------+-----
 PTB-2023-11-07-000276 | mz       | 694ff86b-8030-4546-9d56-77ed94e9139d | 8f8665b6-ed1d-4d7c-ab46-e8c5a908a6e7 | a902ca15-8f0a-4a4b-867c-530603c56c19 | 
98874289-750e-4811-ab1f-0b0c2dc5f0f2 | 624bf45e-b977-438b-967c-4bd487245ee7 | 624bf45e-b977-438b-967c-4bd487245ee7 |      1699346171792 | {"fields": [{"k
ey": "key1", "value": "value1"}], "schema": "registration", "version": 1} | 1699346174212 |    1699346174212 |          1 | f         |                  
 |                        |                 |                      | 
(1 row)

unifieddevdb=> select * from project_staff limit 1;
          id           | tenantid |              projectid               |               staffid                |   startdate   |    enddate    |        
                           additionaldetails                                    |              createdby               |            lastmodifiedby       
     |  createdtime  | lastmodifiedtime | rowversion | isdeleted 
-----------------------+----------+--------------------------------------+--------------------------------------+---------------+---------------+--------
--------------------------------------------------------------------------------+--------------------------------------+---------------------------------
-----+---------------+------------------+------------+-----------
 PTS-2023-12-14-000010 | mz       | 694ff86b-8030-4546-9d56-77ed94e9139d | 764b4522-8e28-4535-98bc-eee44965c518 | 1702550214071 | 9983874101527 | {"field
s": [{"key": "key", "value": "value"}], "schema": "registration", "version": 1} | 0140873d-1f42-4a56-a12a-a6e1ec29992c | 0140873d-1f42-4a56-a12a-a6e1ec29
992c | 1702550214926 |    1702550214926 |          1 | f
(1 row)

unifieddevdb=> select * from project_facility limit 1;
          id          | tenantid |              projectid               |     facilityid      |                                                      addi
tionaldetails                                                      |              createdby               |            lastmodifiedby            |  creat
edtime  | lastmodifiedtime | rowversion | isdeleted 
----------------------+----------+--------------------------------------+---------------------+----------------------------------------------------------
-------------------------------------------------------------------+--------------------------------------+--------------------------------------+-------
--------+------------------+------------+-----------
 PF-2023-10-11-000001 | mz       | 71743b1d-8a73-4fb9-8e61-1166c1555509 | F-2023-10-10-000002 | {"fields": [{"key": "test_12bc5f24692f", "value": "test_b
f376bce4c01"}], "schema": "test_e37466be924cjhghjg", "version": 8} | 24a4254a-ebaa-4999-b01a-3bb526968285 | 24a4254a-ebaa-4999-b01a-3bb526968285 | 169701
4377115 |    1697014377115 |          1 | f
(1 row)

unifieddevdb=> select * from individual limit 1;
                  id                  | userid | clientreferenceid | tenantid |   givenname   | familyname | othernames | dateofbirth | gender | bloodgro
up |                mobilenumber                 | altcontactnumber | email | fathername | husbandname |                photo                 |          
                                                                                                      additionaldetails                                  
                                                                              |              createdby               |            lastmodifiedby         
   |  createdtime  | lastmodifiedtime | rowversion | isdeleted |     individualid      | relationship | issystemuser |  username  |  type   |            
                                                                                                                    roles                                
                                                                                                 |               useruuid               | issystemuseract
ive | clientcreatedtime | clientlastmodifiedtime | clientcreatedby | clientlastmodifiedby 
--------------------------------------+--------+-------------------+----------+---------------+------------+------------+-------------+--------+---------
---+---------------------------------------------+------------------+-------+------------+-------------+--------------------------------------+----------
---------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------+--------------------------------------+-----------------------------------
---+---------------+------------------+------------+-----------+-----------------------+--------------+--------------+------------+---------+------------
---------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------+--------------------------------------+----------------
----+-------------------+------------------------+-----------------+----------------------
 d856b97f-5730-4d6d-a4f0-3f3de0f97a7a | 10571  |                   | pg.citya | Hariprasad Up |            |            | 2007-01-20  | MALE   |         
   | 214148|9fUv/9a2nQrYoDoe+EP9iLgllzbmnLn8Cmo= |                  |       |            |             | 4e357c23-2de7-4b9d-b90a-bc8e136bcc76 | {"fields"
: [{"key": "FUNCTIONAL_ROLE_1", "value": "SANITATION_HELPER"}, {"key": "EMPLOYMENT_TYPE_1", "value": "FIXED"}, {"key": "FUNCTIONAL_ROLE_COUNT", "value": 
"01"}, {"key": "EMPLOYER", "value": "ULB"}], "schema": null, "version": null} | ad7d0d7f-0946-4997-aa37-793421822657 | ad7d0d7f-0946-4997-aa37-7934218226
57 | 1737362588203 |    1737362588203 |          1 | f         | IND-2025-01-20-024929 |              | t            | 8756877575 | CITIZEN | [{"code": "
SANITATION_HELPER", "name": null, "tenantId": "pg.citya", "description": null}, {"code": "SANITATION_WORKER", "name": null, "tenantId": "pg.citya", "desc
ription": null}, {"code": "CITIZEN", "name": null, "tenantId": "pg.citya", "description": null}] | df882059-dcdc-473b-b755-10f9f2026279 | t              
    |                   |                        |                 | 
(1 row)

unifieddevdb=> select * from stock limit 1;
 id | clientreferenceid | tenantid | facilityid | productvariantid | quantity | referenceid | referenceidtype | transactiontype | transactionreason | tra
nsactingpartyid | transactingpartytype | additionaldetails | createdby | createdtime | lastmodifiedby | lastmodifiedtime | rowversion | isdeleted | waybi
llnumber | dateofentry | clientcreatedtime | clientlastmodifiedtime | clientcreatedby | clientlastmodifiedby | sendertype | receivertype | senderid | rec
eiverid 
----+-------------------+----------+------------+------------------+----------+-------------+-----------------+-----------------+-------------------+----
----------------+----------------------+-------------------+-----------+-------------+----------------+------------------+------------+-----------+------
---------+-------------+-------------------+------------------------+-----------------+----------------------+------------+--------------+----------+----
--------
(0 rows)

unifieddevdb=> select * from stock_reconciliation limit 1;
ERROR:  relation "stock_reconciliation" does not exist
LINE 1: select * from stock_reconciliation limit 1;
                      ^
unifieddevdb=> select * from facility limit 1;
         id          | tenantid | ispermanent |           name           |      usage       | storagecapacity |              addressid               |   
                                                   additionaldetails                                                      |              createdby       
        |  createdtime  |            lastmodifiedby            | lastmodifiedtime | rowversion | isdeleted | clientreferenceid 
---------------------+----------+-------------+--------------------------+------------------+-----------------+--------------------------------------+---
--------------------------------------------------------------------------------------------------------------------------+------------------------------
--------+---------------+--------------------------------------+------------------+------------+-----------+-------------------
 F-2023-09-14-000001 | mz       | t           | Facility2 MDA-LF-Nairobi | Storing Resource |             200 | a85afcd2-5303-4028-be8b-0d28643b4a7c | {"
fields": [{"key": "test_12bc5f24692f", "value": "test_bf376bce4c01"}], "schema": "test_e37466be924cjhghjg", "version": 8} | 24a4254a-ebaa-4999-b01a-3bb52
6968285 | 1694683590334 | 24a4254a-ebaa-4999-b01a-3bb526968285 |    1694683590334 |          1 | f         | 
(1 row)

unifieddevdb=> select * from product limit 1;
         id          | tenantid | type |    name    | manufacturer |                                       additionaldetails                             
          |              createdby               |            lastmodifiedby            |  createdtime  | lastmodifiedtime | rowversion | isdeleted 
---------------------+----------+------+------------+--------------+-------------------------------------------------------------------------------------
----------+--------------------------------------+--------------------------------------+---------------+------------------+------------+-----------
 P-2023-09-14-000003 | mz       | DRUG | Ivermectin | Cipla        | {"fields": [{"key": "form", "value": "tablet"}], "schema": "test_3e1c7976b4d6", "ver
sion": 1} | 24a4254a-ebaa-4999-b01a-3bb526968285 | 24a4254a-ebaa-4999-b01a-3bb526968285 | 1694677746469 |    1694677746469 |          1 | f
(1 row)

unifieddevdb=> select * from product_variant limit 1;
           id           | tenantid |      productid      |      sku       | variation |                               additionaldetails                  
              |              createdby               |            lastmodifiedby            |  createdtime  | lastmodifiedtime | rowversion | isdeleted 
------------------------+----------+---------------------+----------------+-----------+------------------------------------------------------------------
--------------+--------------------------------------+--------------------------------------+---------------+------------------+------------+-----------
 PVAR-2023-10-10-000001 | mz       | P-2023-10-10-000004 | Ivermectin 5mg | 5mg       | {"fields": [{"key": "weight", "value": "5g"}], "schema": "test", 
"version": 2} | 24a4254a-ebaa-4999-b01a-3bb526968285 | 24a4254a-ebaa-4999-b01a-3bb526968285 | 1696928679039 |    1696928679039 |          1 | f
(1 row)

unifieddevdb=> select * from service limit 1;
                  id                  | tenant_id | business_service  | module |                  service_code                  |  status  |      additio
nal_details      |              createdby               |           last_modifiedby            |       created_at       |         updated_at         | ve
rsion 
--------------------------------------+-----------+-------------------+--------+------------------------------------------------+----------+-------------
-----------------+--------------------------------------+--------------------------------------+------------------------+----------------------------+---
------
 160ab17f-d66d-4c98-b07f-a453dc23af53 | dev       | Management_System | Events | events-management_system-svc-2026-06-16-001351 | INACTIVE | {"note": "in
itial creation"} | d2cfee97-9611-48eb-957a-4512a15e9e22 | 012c5160-a258-4ab9-b72f-0e9ff5f31c2a | 2026-06-16 11:29:01+00 | 2026-08-04 11:06:12.948+00 |   
    2
(1 row)

unifieddevdb=> select * from stock_reconciliation_log limit 1;
 id | clientreferenceid | tenantid | facilityid | dateofreconciliation | calculatedcount | physicalrecordedcount | commentsonreconciliation | createdby |
 createdtime | lastmodifiedby | lastmodifiedtime | additionaldetails | rowversion | isdeleted | productvariantid | referenceid | referenceidtype | client
createdtime | clientlastmodifiedtime | clientcreatedby | clientlastmodifiedby 
----+-------------------+----------+------------+----------------------+-----------------+-----------------------+--------------------------+-----------+
-------------+----------------+------------------+-------------------+------------+-----------+------------------+-------------+-----------------+-------
------------+------------------------+-----------------+----------------------


