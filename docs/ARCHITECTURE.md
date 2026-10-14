# Orven architecture

## English

### Owners

The native executable remains Toolbox. ToolboxCore owns app metadata, locale/theme, filesystem identity, migration and bounded system/APFS inspection. ToolboxMonitoring owns coordinator cadence, processes/rates/hardware/SMC, health records/baselines, connection observations and bounded network tools. ToolboxStorage owns scanning/review/Trash/recovery/projects/applications. ToolboxChanges owns installer/snapshot/evidence/timeline workflows.

### Demand and data

One monitoring coordinator serves active main-window or optional menu-bar demand; sleep/inactivity pause sampling. UI snapshot publication is throttled while recording/history reuse original timestamps. HealthHistoryStore serializes versioned bounded writes off main actor. Network page owns one cancellable operation and visible-page path callbacks; probes use direct fixed arguments, never a shell. No extra background sampler or persistent endpoint history is added.

### Compatibility and trust

Public app is Orven.app version3.0.0, executable Toolbox, bundleIDcom.thang.toolbox and ApplicationSupportToolbox preserved. Four locale resources share stable user-visible strings. Mutations revalidate paths/process identities at execution and require explicit review. Ad-hoc integrity is not Apple notarization. [Architecture diagram](diagrams/toolbox-architecture.html), [Health](monitoring/HEALTH-WORKFLOWS.md), [Network](monitoring/NETWORK-TOOLS.md).

## Tiếng Việt

### Owners

ExecutablevẫnToolbox. ToolboxCoremetadata/locale/theme/filesystemidentity/migration/systemAPFSread;ToolboxMonitoringcoordinator/process/rate/hardwareSMC/health/network;ToolboxStoragescan/review/Trash/recovery/projects/apps;ToolboxChangesinstaller/snapshot/evidence/timeline.

### Demand and data

Mộtcoordinatorchoactivewindow/menu-baropt-in;sleep/inactivepause. UIthrottled;history/recordingdùngtimestampgốc. HealthHistoryStorewritesversionedboundedoff-main. Networkpage1operationcancel+pathcallbacksvisible,helperdirectargsnoshell. Khôngextrasampler/endpointdiskhistory.

### Compatibility and trust

AppOrven.app3.0.0/executableToolbox/bundleID/data giữ tươngthích.4locales. Mutationrevalidatepath/processkhi chạy/reviewexplicit. Ad-hockhôngnotarization. [Diagram](diagrams/toolbox-architecture.html)/[Health](monitoring/HEALTH-WORKFLOWS.md)/[Network](monitoring/NETWORK-TOOLS.md).

## 日本語

### Owners

ExecutableはToolbox。ToolboxCoreはmetadata/locale/theme/identity/migration/systemAPFSread、ToolboxMonitoringはcoordinator/process/rate/hardwareSMC/health/network、ToolboxStorageはscan/review/Trash/recovery/projects/apps、ToolboxChangesはinstaller/snapshot/evidence/timeline。

### Demand and data

1coordinatorがactivewindow/opt-inmenu-bar demandを処理、sleep/inactiveでpause。UIthrottle、history/recordingは原timestamp。Storeはoff-mainversionedboundedwrite。Networkpageは1canceloperation/visiblepathcallback、directargs/no shell。Extra sampler/endpointdiskhistoryなし。

### Compatibility and trust

AppOrven.app3.0.0/executableToolbox/bundleID/data互換維持、4locale。Mutationは実行時identity/pathrevalidateと明示review。Ad-hocはnotarizationではありません。[Diagram](diagrams/toolbox-architecture.html)/[Health](monitoring/HEALTH-WORKFLOWS.md)/[Network](monitoring/NETWORK-TOOLS.md)。
