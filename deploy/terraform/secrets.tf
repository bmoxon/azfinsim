#-- Add secrets to keyvault 
resource "azurerm_key_vault_secret" "redis" {
  #count        = local.dbg-noredis ? 0 : 1
  name         = format("AzFinSimRedisKey-%s", random_string.suffix.result)
  value        = local.dbg-noredis ? "noredis-secret" : azurerm_redis_cache.azfinsim[0].primary_access_key
  key_vault_id = azurerm_key_vault.azfinsim.id
}
resource "azurerm_key_vault_secret" "storage" {
  name         = format("AzFinSimStorageSas-%s", random_string.suffix.result)
  value        = data.azurerm_storage_account_blob_container_sas.azfinsim.sas
  key_vault_id = azurerm_key_vault.azfinsim.id
}
resource "azurerm_key_vault_secret" "azcr" {
  name         = format("AzFinSimACRKey-%s", random_string.suffix.result)
  value        = azurerm_container_registry.azfinsim.admin_password
  key_vault_id = azurerm_key_vault.azfinsim.id
}
resource "azurerm_key_vault_secret" "appinsights" {
  name         = format("AzFinSimAppInsightsKey-%s", random_string.suffix.result)
  value        = azurerm_application_insights.azfinsim.instrumentation_key
  key_vault_id = azurerm_key_vault.azfinsim.id
}
resource "azurerm_key_vault_secret" "headnode_vm_ssh_privkey" {
  name         = format("AzFinSimHeadnodePrivKey-%s", random_string.suffix.result)
  value        = tls_private_key.azfinsim_headnode_ssh.private_key_pem
  key_vault_id = azurerm_key_vault.azfinsim.id
}
resource "azurerm_key_vault_secret" "headnode_vm_ssh_publickey" {
  name         = format("AzFinSimHeadnodePubKey-%s", random_string.suffix.result)
  value        = tls_private_key.azfinsim_headnode_ssh.public_key_openssh
  key_vault_id = azurerm_key_vault.azfinsim.id
}
