Demo package for creating a task queue backed by a nodejs google run container service.


## How to use
To deploy the current commit to beta
1. authenticate with your account (must be an organization account)
  * get your billing account from the console.
  * get your org_id from the console.
  * run helpers/setup-sa.sh -o ORGANIZATION_ID -b BILLING_ID
  * This will create a new "seed" account with a role project-factory-<number>@... <-- write this down. This is your terraform service account.
2. BILLING_ACCOUNT=... TERRAFORM_SA=... ORG_ID=... make bootstrap_beta 
   * review and accept the changes
   * accept migrating state to s3
   * commit the newly added backend.tf file to the repository.
   * NEVER DO THIS TARGET AGAIN UNLESS YOU WANT TO CREATE A BRANCH ACCOUNT FOR DEV TESTING (TODO INSTRUCTIONS)

--- THIS SHOULD GENERALLY ONLY HAPPEN IN GITHUB ACTIONS. IF YOU BUILD THESE AGAINST THE MAIN ACCOUNT YOU WILL DEPLOY TO THE REAL PROJECTS -----
3. make build_beta
   * This should build the container image and upload it a repo in the project you just created
4. make deploy_beta
   * This will deploy the cloudrun service and task queue to your beta project with the image version you just uploaded.
