resource "google_workflows_workflow" "data_pipeline" {
  name            = "${var.environment}-data-pipeline"
  region          = var.region
  description     = "Data processing pipeline workflow"
  service_account = google_service_account.workflow_sa.email
  
  source_contents = <<-EOF
    main:
      params: [args]
      steps:
        - init:
            assign:
              - project: ${var.project_id}
              - location: ${var.region}
              - bucket: "test-workflow-bucket-20250628"
        
        - checkBucket:
            call: googleapis.storage.v1.objects.list
            args:
              bucket: $${bucket}
            result: objects
        
        - processFiles:
            for:
              value: file
              in: $${objects.items}
              steps:
                - logFile:
                    call: sys.log
                    args:
                      text: "Processing file"
        
        - complete:
            return: "Workflow completed successfully"
  EOF
}

resource "google_service_account" "workflow_sa" {
  account_id   = "${var.environment}-workflow-sa"
  display_name = "Workflow Service Account"
}

resource "google_project_iam_member" "workflow_sa_binding" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.workflow_sa.email}"
}
