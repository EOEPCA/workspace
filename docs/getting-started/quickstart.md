# Quickstart

This quickstart demonstrates he capabilities of trhe Workspace BB through a fictive end-to-end scenario using the existing deplyoment *eoepca-demo* Kubereners clsuter. It highlights the roles of different personas — operator, manager, and user — and walks through workspace creation, member management, data sharing, and collaborative use of Datalabs.

The *eoepca-demo*  system is preconfigured as follows:

- **Object Storage:** Uses **MinIO** as the S3-compatible backend but other storages like AWS S3 or OTC OBS work as well
- **Session Mode:** Set to `Auto` (on-demand start/stop). It can also be configured as `AlwaysOn` for long-running sessions with this scenario.
- **vCluster Mode:** Enabled (`useVcluster=true`) to provide strong workspace isolation but namespace mode is also fine for this quickstart
- **Existing Workspaces:** Pre-created for `alice`, `bob`, and `eric` as `ws-alice`, `ws-bob`, and `ws-eric`.

...