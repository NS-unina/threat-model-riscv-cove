/* Attack goal */
%attackGoal(tnd(domainManager)).
attackGoal(canDiscloseInformation(ControlAction13)).

/* Attacker location */
attackerType(directAttacker).
attackerPrivilege(logicPrivilege).
attackerLocated(untrustedSupervisorDomain).

/* Vuln */
weaknessExist(interruptManager, cwe20).
weaknessExist(domainManager, cwe459).

/* Control flows */
controlFlow(untrustedSupervisorDomain, interruptManager, ControlAction01).
controlFlow(interruptManager, domainManager, ControlAction16).
