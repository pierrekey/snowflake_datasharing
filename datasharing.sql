-- =============================================
-- Author:      Pierre COste - Keyrus
-- Create date: May 2019
-- Description: Script to try Snowflake sharing capabilities
-- =============================================


/* Create a finance table in private schema  */
/* Insert data with last column access group     */


use role sysadmin;

create or replace table mapetiteentreprise.private.f_finance (
    name string,
    date date,    
    revenue float,
    margin float,
    cost float,    
    access_id string /* granularity for access */ )
    cluster by (date);

insert into mapetiteentreprise.private.f_finance
    values('Franchise 1',dateadd(day,  -1,current_date()), '20452.5', 1106.5, 116.6,  'F_1'),
          ('Franchise 1',dateadd(month,-2,current_date()), '24823.1', 5126.5, 716.6,  'F_1'),
          ('Franchise 2',dateadd(day,  -1,current_date()), '5393.7',  528.0,  1048.9,  'F_2'),
          ('Franchise 2',dateadd(month,-2,current_date()), '49513',  158.0,  156.9, 'F_2'),
          ('Franchise 3', dateadd(day,  -1,current_date()), '8245.6', 3175.2, 895.4, 'F_3'),
          ('Franchise 3', dateadd(month,-2,current_date()), '46135.6', 1175.2, 1000.4,  'F_3"');

/* Create sharing access group table  */
create or replace table mapetiteentreprise.private.sharing_access (
  access_id string,
  snowflake_account string
);


/* I can access to all data    */

insert into mapetiteentreprise.private.sharing_access values('F_1', current_account());
insert into mapetiteentreprise.private.sharing_access values('F_2', current_account());
insert into mapetiteentreprise.private.sharing_access values('F_3', current_account());

/* Create a secure view in the 'public' schema.       */
/* THis table filter rows by user rights                       */

create or replace secure view mapetiteentreprise.public.f_finance as
    select name,    date ,revenue ,margin ,cost    
    from mapetiteentreprise.private.f_finance sd
    join mapetiteentreprise.private.sharing_access sa on sd.access_id = sa.access_id
    and sa.snowflake_account = current_account();

grant select on mapetiteentreprise.public.f_finance to public;


/* After create read only account, insert sharing access matrix  */

insert into mapetiteentreprise.private.sharing_access values('F_1', 'XXX');
insert into mapetiteentreprise.private.sharing_access values('F_2', 'XYX');
insert into mapetiteentreprise.private.sharing_access values('F_3', 'XYX');

/* We can simulate with impersonate user */

/*      alter session set simulated_data_sharing_consumer=XXX;    
        alter session unset simulated_data_sharing_consumer='ACCT1';

*/

/* Create a share using the ACCOUNTADMIN role. */

use role accountadmin;

create or replace share mapetiteentreprise_shared
  comment = 'Partage des données financières aux franchisés';

show shares;


/*  Grant privileges on the database objects to include in the share.  */

grant usage on database mapetiteentreprise to share mapetiteentreprise_shared;

grant usage on schema mapetiteentreprise.public to share mapetiteentreprise_shared;

grant select on mapetiteentreprise.public.f_finance to share mapetiteentreprise_shared;


/*  Confirm the contents of the share. */

show grants to share mydb_shared;


/* Add accounts to the share.                                    */

alter share mapetiteentreprise_shared set accounts = XXXX,XYX;


