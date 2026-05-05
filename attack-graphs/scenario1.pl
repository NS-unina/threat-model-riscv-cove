/* Attack goal */
%attackGoal(t1556(domainManager)).
attackGoal(canDiscloseInformation(ControlAction13)).


/* Attacker location */
%attackerLocated(logicalAdversary).
%attackerPrivilege(directAttacks).

attackerType(directAttacker).
attackerPrivilege(logicPrivilege).
attackerLocated(untrustedSupervisorDomain).


/* Vuln */
weaknessExist(interruptManager, cwe20).
%weaknessExist(interruptManager, cwe754).
weaknessExist(domainManager, cwe459).

/* Control flows */
controlFlow(untrustedSupervisorDomain, interruptManager, ControlAction01).
controlFlow(interruptManager, domainManager, ControlAction16).
controlFlow(domainManager, pmp, ControlAction13).