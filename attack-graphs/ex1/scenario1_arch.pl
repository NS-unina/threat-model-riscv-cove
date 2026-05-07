/* Goal */
attackGoal(disclosure(domainManager)).

/* Attacker */
attackerLocated(untrustedSupervisorDomain).
attackerPrivilege(logicalPrivilege).
attackType(directAttacker).

/* Weakness */
weaknessExist(interruptManager, cwe20).
weaknessExist(domainManager, cwe200).

/* Flows */
controlFlow(untrustedSupervisorDomain, interruptManager, coveH_SBI).
controlFlow(interruptManager, domainManager, requestDomainManagerServices).
controlFlow(domainManager, pmp, applyDomainMetadata).
