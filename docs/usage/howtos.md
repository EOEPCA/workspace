# How-Tos

How-tos to communicate usage by example.

## Workspace Building Block

### UC1: Dedicated Workspace for Users and Projects

**User Story:** As a user, I want to use an instance of a building block or component (e.g., resource discovery, data access) which is dedicated to my own or my project workspace.

**Tech Standards:** Kubernetes, GitOps

**Epic:** E5310

**Building Block:** Workspace

**How-To:**

1. **Create a Workspace:** Use the Workspace Controller to create a new workspace dedicated to your project or individual use.
2. **Provision Services:**  Utilize the Workspace Controller to provision the necessary services within your workspace, such as resource discovery, data access, or visualization tools.
3. **Access Services:** Access the provisioned services within your workspace using the provided APIs or user interfaces.

### UC2: Workspace Provisioning and Management

**User Story:** As a platform operator, I want to leverage a SOTA solution to provision and manage workspaces for projects/groups.

**Tech Standards:** Kubernetes, GitOps

**Epic:** E5310

**Building Block:** Workspace

**How-To:**

1. **Configure Workspace Templates:** Define templates for different workspace types (e.g., individual user, project team) using GitOps principles.
2. **Provision Workspaces:** Use the Workspace Controller to provision new workspaces based on the defined templates.
3. **Manage Workspaces:** Monitor and manage workspace resources, including services, storage, and user access, through the Workspace Controller.

## Storage Building Block

### UC3: S3 Object Storage for Data Organization

**User Story:** As a user, I want an S3 object storage to organize and curate data.

**Tech Standards:** S3

**Epic:** E5350

**Building Block:** Workspace

**How-To:**

1. **Create Storage Buckets:** Use the Storage Controller to create new S3 buckets within your workspace.
2. **Upload Data:** Upload your data files to the created buckets using the provided S3 API or HTTP access.
3. **Organize Data:** Organize your data within the buckets using folders and file naming conventions.

## Security Building Block

### UC4: IAM Control for Users

**User Story:** As a platform operator, I want to keep control on IAM for my users.

**Tech Standards:** OAuth2

**Epic:** E5340

**Building Block:** Workspace

**How-To:**

1. **Configure IAM Roles:** Define IAM roles with specific permissions for different user groups (e.g., data scientists, project managers).
2. **Assign Roles to Users:** Assign the appropriate IAM roles to users based on their responsibilities and access needs.
3. **Monitor Access:** Monitor user access and activity logs to ensure security and compliance.

## Application Hub Building Block

### UC5: Delegated Workspace Service Instantiation

**User Story:** As a platform operator, I want to delegate Workspace Service instantiation to the end-users without compromising security.

**Tech Standards:** Kubernetes, Helm

**Epic:** E5320

**Building Block:** Workspace, Application Hub, MLOps

**How-To:**

1. **Create Helm Charts:** Package Workspace Services as Helm charts, including dependencies and configuration options.
2. **Publish Charts to Application Hub:** Publish the Helm charts to the Application Hub, making them accessible to users.
3. **User Service Instantiation:** Allow users to install and configure Workspace Services from the Application Hub using Helm.

## Resource Management Building Block

### UC6: Runtime Resource Management

**User Story:** As a platform operator, I want to easily turn on and off projects/groups runtime resources to save costs.

**Tech Standards:** Kubernetes

**Epic:** E5320

**Building Block:** Workspace

**How-To:**

1. **Configure Resource Scaling:** Define resource scaling policies for different workspace types or services.
2. **Automate Resource Management:** Use Kubernetes features like autoscaling and resource quotas to automatically manage resource allocation based on usage patterns.
3. **Monitor Resource Usage:** Monitor resource consumption and adjust scaling policies as needed to optimize costs.

## Data Management Building Block

### UC7: Data Integration and Collaboration

**User Story:** As a user, I want to integrate (copy as well as referencing) data in the project/group space for collaboration.

**Tech Standards:** S3

**Epic:** E5330

**Building Block:** Workspace

**How-To:**

1. **Upload Data to Workspace Buckets:** Upload data files to the workspace's S3 buckets.
2. **Share Data with Collaborators:** Grant access to the workspace buckets to collaborators, allowing them to view, download, or modify data.
3. **Reference Data:** Use data references (e.g., URLs, S3 paths) to link to data stored in the workspace buckets, enabling collaboration without duplicating data.

### UC8: Data Discovery and Exploration

**User Story:** As a user, I want to have an exhaustive view on all available data in the project/group space.

**Epic:** E5330

**Building Block:** Workspace

**How-To:**

1. **Use Resource Discovery Service:** Utilize the Workspace's resource discovery service to browse and search for available data within the workspace.
2. **Explore Data Metadata:** Access metadata associated with data files, including file size, format, and creation date.
3. **Filter and Sort Data:** Filter and sort data based on specific criteria to find relevant information.

### UC9: Data Change Tracking

**User Story:** As a user, I want to be able to trace changes on data.

**Epic:** E5330

**Building Block:** Workspace

**How-To:**

1. **Enable Versioning:** Configure versioning for the workspace's S3 buckets to track changes to data files.
2. **Access Data History:** View previous versions of data files and track changes made over time.
3. **Restore Previous Versions:** Restore previous versions of data files if needed.

### UC10: Reproducible Data Exploration and Processing

**User Story:** As a user, I want to be able to explore / process / experiment with stable snapshots of data for reproducibility in a scalable way with common software libraries.

**Tech Standards:** S3, fsspec

**Epic:** E5330

**Building Block:** Workspace

**How-To:**

1. **Create Data Snapshots:** Create snapshots of data within the workspace's S3 buckets to ensure reproducibility.
2. **Use fsspec for Data Access:** Utilize the fsspec library to access data snapshots from within your analysis environment.
3. **Scale Data Processing:** Leverage the scalability of the underlying infrastructure to process large datasets efficiently.

## Application Hub Building Block

### UC11: Familiar Data Libraries and Tools

**User Story:** As a user, I want to use my familiar data library and tool stack for exploration and curation.

**Tech Standards:** Kubernetes, Helm

**Epic:** E5350

**Building Block:** Workspace

**How-To:**

1. **Install Data Libraries:** Install your preferred data libraries and tools within your workspace using Helm charts from the Application Hub.
2. **Configure Libraries:** Configure the installed libraries and tools to access data within the workspace.
3. **Use Familiar Tools:** Utilize your familiar data libraries and tools for exploration, analysis, and curation.

### UC12: Custom Applications and Tools

**User Story:** As a user, I want to bring a custom set of existing applications and tools close to the data.

**Tech Standards:** Kubernetes, Helm

**Epic:** E5360

**Building Block:** Workspace, Application Hub, MLOps

**How-To:**

1. **Package Applications as Helm Charts:** Package your custom applications and tools as Helm charts.
2. **Publish Charts to Application Hub:** Publish the Helm charts to the Application Hub.
3. **Deploy Applications to Workspace:** Deploy your custom applications and tools to your workspace using Helm.
