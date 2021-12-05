{ ... }:

# Laptop which sits with lid closed most of the time shall not sleep
{
  services.logind.lidSwitch = "ignore";
  services.logind.lidSwitchDocked = "ignore";
  services.logind.lidSwitchExternalPower = "ignore";
}
