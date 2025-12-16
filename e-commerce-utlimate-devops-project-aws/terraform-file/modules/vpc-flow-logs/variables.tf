variable "enable_flow_log" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_log_destination_type" {
  description = "Type of flow log destination (cloud-watch-logs or s3)"
  type        = string
  default     = "s3"
  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_log_destination_type)
    error_message = "Flow log destination type must be either 'cloud-watch-logs' or 's3'."
  }
}

variable "flow_log_traffic_type" {
  description = "Type of traffic to capture (ALL, ACCEPT, REJECT)"
  type        = string
  default     = "ALL"
  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.flow_log_traffic_type)
    error_message = "Flow log traffic type must be ALL, ACCEPT, or REJECT."
  }
}

variable "vpc_id" {
  description = "VPC ID for flow logs"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for flow logs"
  type        = string
  default     = ""
}

variable "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for flow logs"
  type        = string
  default     = "/aws/vpc/flowlogs"
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "flow_log_iam_role_name" {
  description = "IAM role name for flow logs"
  type        = string
  default     = "flowlogsRole"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
