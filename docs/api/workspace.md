# API Reference

Packages:

- [epca.eo/v1beta1](#epcaeov1beta1)

# epca.eo/v1beta1

Resource Types:

- [XWorkspace](#xworkspace)




## XWorkspace
<sup><sup>[↩ Parent](#epcaeov1beta1 )</sup></sup>








<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Description</th>
            <th>Required</th>
        </tr>
    </thead>
    <tbody><tr>
      <td><b>apiVersion</b></td>
      <td>string</td>
      <td>epca.eo/v1beta1</td>
      <td>true</td>
      </tr>
      <tr>
      <td><b>kind</b></td>
      <td>string</td>
      <td>XWorkspace</td>
      <td>true</td>
      </tr>
      <tr>
      <td><b><a href="https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.27/#objectmeta-v1-meta">metadata</a></b></td>
      <td>object</td>
      <td>Refer to the Kubernetes API documentation for the fields of the `metadata` field.</td>
      <td>true</td>
      </tr><tr>
        <td><b><a href="#xworkspacespec">spec</a></b></td>
        <td>object</td>
        <td>
          <br/>
        </td>
        <td>true</td>
      </tr><tr>
        <td><b><a href="#xworkspacestatus">status</a></b></td>
        <td>object</td>
        <td>
          <br/>
        </td>
        <td>false</td>
      </tr></tbody>
</table>


### XWorkspace.spec
<sup><sup>[↩ Parent](#xworkspace)</sup></sup>





<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Description</th>
            <th>Required</th>
        </tr>
    </thead>
    <tbody><tr>
        <td><b>owner</b></td>
        <td>string</td>
        <td>
          <br/>
        </td>
        <td>true</td>
      </tr><tr>
        <td><b>defaultBucket</b></td>
        <td>string</td>
        <td>
          <br/>
        </td>
        <td>false</td>
      </tr><tr>
        <td><b>extraBuckets</b></td>
        <td>[]string</td>
        <td>
          <br/>
          <br/>
            <i>Default</i>: []<br/>
        </td>
        <td>false</td>
      </tr><tr>
        <td><b><a href="#xworkspacespecgrantsindex">grants</a></b></td>
        <td>[]object</td>
        <td>
          <br/>
          <br/>
            <i>Default</i>: []<br/>
        </td>
        <td>false</td>
      </tr><tr>
        <td><b>linkedBuckets</b></td>
        <td>[]string</td>
        <td>
          <br/>
          <br/>
            <i>Default</i>: []<br/>
        </td>
        <td>false</td>
      </tr><tr>
        <td><b>members</b></td>
        <td>[]string</td>
        <td>
          <br/>
          <br/>
            <i>Default</i>: []<br/>
        </td>
        <td>false</td>
      </tr><tr>
        <td><b>subscription</b></td>
        <td>enum</td>
        <td>
          <br/>
          <br/>
            <i>Enum</i>: gold, silver, bronze, trial<br/>
            <i>Default</i>: trial<br/>
        </td>
        <td>false</td>
      </tr><tr>
        <td><b>vcluster</b></td>
        <td>enum</td>
        <td>
          <br/>
          <br/>
            <i>Enum</i>: active, suspended, disabled<br/>
            <i>Default</i>: active<br/>
        </td>
        <td>false</td>
      </tr></tbody>
</table>


### XWorkspace.spec.grants[index]
<sup><sup>[↩ Parent](#xworkspacespec)</sup></sup>





<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Description</th>
            <th>Required</th>
        </tr>
    </thead>
    <tbody><tr>
        <td><b>bucket</b></td>
        <td>string</td>
        <td>
          <br/>
        </td>
        <td>true</td>
      </tr><tr>
        <td><b>grantees</b></td>
        <td>[]string</td>
        <td>
          <br/>
        </td>
        <td>true</td>
      </tr></tbody>
</table>


### XWorkspace.status
<sup><sup>[↩ Parent](#xworkspace)</sup></sup>





<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Description</th>
            <th>Required</th>
        </tr>
    </thead>
    <tbody></tbody>
</table>
