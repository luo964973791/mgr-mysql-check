USE sys;

 

DELIMITER $$

 

 

DROP FUNCTION gr_member_in_primary_partition$$

 

DROP VIEW gr_member_routing_candidate_status$$

 

CREATE FUNCTION gr_member_in_primary_partition()

RETURNS VARCHAR(3)

DETERMINISTIC

BEGIN

  RETURN (SELECT IF( MEMBER_STATE='ONLINE' AND ((SELECT COUNT(*) FROM

performance_schema.replication_group_members WHERE MEMBER_STATE != 'ONLINE') >=

((SELECT COUNT(*) FROM performance_schema.replication_group_members)/2) = 0),

'YES', 'NO' ) FROM performance_schema.replication_group_members JOIN

performance_schema.replication_group_member_stats rgms USING(member_id) WHERE rgms.MEMBER_ID=@@SERVER_UUID);

END$$

 

 

CREATE VIEW gr_member_routing_candidate_status AS SELECT

sys.gr_member_in_primary_partition() as viable_candidate,

IF( (SELECT (SELECT GROUP_CONCAT(variable_value) FROM

performance_schema.global_variables WHERE variable_name IN ('read_only',

'super_read_only')) != 'OFF,OFF'), 'YES', 'NO') as read_only,

sys.gr_applier_queue_length() as transactions_behind, Count_Transactions_in_queue as 'transactions_to_cert'

from performance_schema.replication_group_member_stats rgms

where rgms.MEMBER_ID=(select gv.VARIABLE_VALUE

 from `performance_schema`.global_variables gv where gv.VARIABLE_NAME='server_uuid');$$

 

DELIMITER ;
