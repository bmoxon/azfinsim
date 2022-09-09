param caches_hpccro_name string = 'hpcc-ro'
param storageAccounts_m3blobnfs_externalid string = '/subscriptions/${subscription().subscriptionId}/resourceGroups/bcmscus-rg/providers/Microsoft.Storage/storageAccounts/m3blobnfs'
param virtualNetworks_hpcvnet_externalid string = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/Krypton-vnet'
param location string = resourceGroup().location

resource caches_hpccro_name_resource 'Microsoft.StorageCache/caches@2021-03-01' = {
  name: caches_hpccro_name
  location: location
  properties: {
    cacheSizeGB: 86491
    directoryServicesSettings: {
      usernameDownload: {
        autoDownloadCertificate: false
        encryptLdapConnection: false
        extendedGroups: false
        requireValidCertificate: false
        usernameSource: 'None'
      }
    }
    networkSettings: {
      mtu: 1500
      ntpServer: 'time.windows.com'
    }
    provisioningState: 'Succeeded'
    securitySettings: {
      accessPolicies: [
        {
          accessRules: [
            {
              access: 'rw'
              filter: '10.2.0.0/24'
              rootSquash: false
              scope: 'network'
              submountAccess: false
              suid: true
            }
          ]
          name: 'compute-subnet-access-policy'
        }
        {
          accessRules: [
            {
              access: 'rw'
              rootSquash: false
              scope: 'default'
              submountAccess: true
              suid: false
            }
          ]
          name: 'default'
        }
        {
          accessRules: [
            {
              access: 'rw'
              rootSquash: false
              scope: 'default'
              submountAccess: true
              suid: false
            }
          ]
          name: 'policyNoSquash'
        }
        {
          accessRules: [
            {
              access: 'rw'
              anonymousGID: '-2'
              anonymousUID: '-2'
              rootSquash: true
              scope: 'default'
              submountAccess: true
              suid: false
            }
          ]
          name: 'policySquash'
        }
      ]
    }
    subnet: '${virtualNetworks_hpcvnet_externalid}/subnets/hpc-cache-ro'
    upgradeStatus: {}
  }
  sku: {
    name: 'Standard_L16G'
  }
}

resource caches_hpccro_name_m3blobnfsc1 'Microsoft.StorageCache/caches/storageTargets@2021-03-01' = {
  parent: caches_hpccro_name_resource
  name: 'm3blobnfsc1'
  properties: {
    blobNfs: {
      target: '${storageAccounts_m3blobnfs_externalid}/blobServices/default/containers/hpccro1'
      usageModel: 'READ_HEAVY_INFREQ'
    }
    junctions: [
      {
        namespacePath: '/p1'
        nfsAccessPolicy: 'default'
        nfsExport: '/'
        targetPath: '/'
      }
    ]
    provisioningState: 'Succeeded'
    targetType: 'blobNfs'
  }
}
