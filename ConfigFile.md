# Description #
```
[General]
load_profile=Cleware

[Description]
name=               String:  Profile name         - Only for tray tooltip
exec=               String:  executable name      - Only for error check (executable not found)
address=            String:  Not used see command strings
outlet=             Integer: Outlet number        - Only for tray tooltip
user=               String:  Not used see command strings
password=           String:  Not used see command strings
state=              Boolean: Not used                   - Empty for False
err_str=            String:  Error response
timeout=            Integer: Not used see command strings - Intervall for auto update status in seconds
updatetime=         Integer: Intervall for update status after changing in milliseconds
autotoggle=         Boolean: Startup toggle state       - Empty for False
toggletime=         Integer: Intervall for toggling (off-toggletime-on) status on icon click in milliseconds
autoupdate=         Boolean: Startup auto update state  - Empty for False
autupd_time=        Integer: Intervall for auto update status in milliseconds
state_str_on=       String:  Indicates outlet is on
state_str_off=      String:  Indicates outlet is off
get_state=          String:  Command for getting outlet state
set_state_on=       String:  Command for setting outlet state on
set_state_off=      String:  Command for setting outlet state off
```