
local target=''
local modem = component.modem
modem.open(2)
modem.broadcast(2, 'return scan()')
print(modem.pullSignal())