variable "subscription_id" {
  description = "ID of the subscription the policy is defined and assigned in (the cyber parts subscription)."
  type        = string
}

variable "region" {
  description = "Region for the policy assignment's system-assigned managed identity."
  type        = string
}
