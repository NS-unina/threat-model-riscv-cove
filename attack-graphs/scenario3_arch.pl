/* Goal */
attackGoal(memoryStealing(pmp)).

/* Attacker */
attackerLocated(untrustedSupervisorDomain).
attackerPrivilege(logicalPrivilege).
attackType(directAttacker).

/* The attacker is a legitimate TSM client: it is in the TSM trust map */
trustMapEntry(untrustedSupervisorDomain, tsm).

/* Victim: another supervisor domain owns converted confidential memory */
ownsConfidentialMemory(victimSupervisorDomain).

/* Weakness */
weaknessExist(interruptManager, cwe20).
weaknessExist(domainManager, cwe862).

/* Flows */
controlFlow(untrustedSupervisorDomain, interruptManager, coveH_SBI).
controlFlow(victimSupervisorDomain, interruptManager, coveH_SBI).
controlFlow(interruptManager, domainManager, requestDomainManagerServices).
controlFlow(domainManager, pmp, applyDomainMetadata).
