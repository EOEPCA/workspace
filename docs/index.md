# Introduction

The documentation for the `Workspace` building block is organised as follows...

* **Introduction**<br>
  Introduction to the BB - including summary of purpose and capabilities.
* **Getting Started**<br>
  Quick start instructions - including installation, e.g. of a local instance.
* **Design**<br>
  Description of the BB design - including its subcomponent architecture and interfaces.
* **Usage**<br>
  Tutorials, How-tos, etc. to communicate usage of the BB.
* **Administration**<br>
  Configuration and maintenance of the BB.
* **API**<br>
  Details of APIs provided by the BB - including endpoints, usage descriptions and examples etc.


## About `Workspace`

The `Workspace` building block provides a comprehensive solution for storing assets and offering services like cataloguing, data (cube) access, and visualization to explore stored assets. Workspaces can cater to individual users or serve as collaborative spaces for groups or projects.

### Workspace Controller

The Workspace Controller acts as an API for workspace administration. This includes:

* **Provisioning and Lifecycle Management:** Creating, updating, and deleting workspaces.
* **Workspace Instance Management:** Configuring and managing individual workspace instances and their associated services [BR066].
* **REST API:** Providing a REST API for workspace administration [BR067].
* **GitOps Approach:** Enabling workspace owners to manage their workspace offerings through a declarative GitOps approach [BR070].
* **Extensibility:** Allowing for the extension of managed services by reusing existing building blocks [BR068, BR069].
* **Resource Efficiency:** Designing for efficient use of platform resources [BR072].
* **Service Management:** Enabling users to manage (enable, disable, suspend) the services provisioned within their workspace [BR071].

### Storage Controller

The Storage Controller provides an API for self-service management of storage buckets. Users can:

* **Create and Manage Buckets:** Create and manage object storage buckets via an API associated with the workspace [BR073, BR074].
* **Bucket Management:** Manage buckets, including listing details like bucket name, service URL, and S3 access credentials [BR075].
* **HTTP Access:** Access buckets via direct HTTP access, supporting HTTP range requests and allowing users to upload assets [BR076, BR077].
* **IAM Integration:** Secure S3 and HTTP access by integrating with the IAM building block [BR078].
* **External Storage Support:** Register and integrate external S3-compatible object storage services [BR079].
* **Unique Identification:** Uniquely identify each S3 object storage service [BR080].

### Workspace Services

The Workspace Services comprise an extensible set of services that can be provisioned within the workspace. These services include:

* **Resource Registration/Discovery:** Enabling the registration and discovery of resources.
* **Data & Datacube Access:** Providing access to data and data cubes.
* **Extensibility:** Supporting arbitrary applications and tooling by reusing existing Helm charts for databases (e.g., PostGIS), JupyterHub, ML tooling (e.g., MLFlow, Tensorboard) [BR081, BR084].
* **Public APIs:** Exposing all workspace services via their public APIs.
* **Scoped Access:** Providing access to resources scoped according to the owning projects and users [BR082, BR083].

### Workspace User Interface

The Workspace User Interface provides a web-based interface for:

* **Workspace Lifecycle Management:** Creating, listing, updating, and deleting workspaces.
* **Workspace Resource Management:** Managing workspace resources, including services, storage buckets, registered resources, and DOI registrations [BR085].
