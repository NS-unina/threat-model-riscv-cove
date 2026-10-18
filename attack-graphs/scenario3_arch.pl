/* Goal */
attackGoal(memoryStealing(domainManager)).

/* Attacker */
attackerLocated(untrustedSupervisorDomain).
attackerPrivilege(logicalPrivilege).
attackType(directAttacker).

/* Weakness */
weaknessExist(interruptManager, cwe20).
weaknessExist(domainManager, cwe862).

/* Flows */
controlFlow(untrustedSupervisorDomain, interruptManager, coveH_SBI).
controlFlow(interruptManager, domainManager, requestDomainManagerServices).
controlFlow(domainManager, pmp, applyDomainMetadata).
