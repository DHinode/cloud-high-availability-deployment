pipeline {

	parameters {
    	booleanParam(
	    	name: 'DESTROY_INFRASTRUCTURE',
	    	defaultValue: false,
	    	description: 'ATTENTION : Si coche, le pipeline va detruire l\'infrastructure !'
        )
    	booleanParam(
	    	name: 'APPLY_BOOL',
	    	defaultValue: false,
	    	description: 'ATTENTION : Si coche, le pipeline va deployer l\'infarstruture !'
        )
    }
    
    agent any
    
    tools {
        terraform 'Terraform-1.x'
    }
    
    environment {
        AWS_KEYS = credentials('aws-key')
    }
    
    stages {
    
        stage('Checkout') { //================================================
            steps {
                git branch: 'main', url: 'https://github.com/DHinode/cloud-high-availability-deployment'
            }
        }
        
        stage('Terraform Init') { //================================================
            steps {
                sh '''
                    export AWS_ACCESS_KEY_ID=$AWS_KEYS_USR
                    export AWS_SECRET_ACCESS_KEY=$AWS_KEYS_PSW
                    terraform init
                '''
            }
        }
        stage('Validate & Plan') { //================================================
            steps {
                sh '''
                    export AWS_ACCESS_KEY_ID=$AWS_KEYS_USR
                    export AWS_SECRET_ACCESS_KEY=$AWS_KEYS_PSW
                    terraform validate
                    terraform plan -out=tfplan
                '''
            }
            post {
                always {
                    stash name: 'tfplan', includes: 'tfplan'
                }
            }
        }
        
        stage('Terraform Apply') { //================================================
            when {
                expression { params.APPLY_BOOL == true }
            }
            steps {
                unstash 'tfplan'
                sh '''
                    export AWS_ACCESS_KEY_ID=$AWS_KEYS_USR
                    export AWS_SECRET_ACCESS_KEY=$AWS_KEYS_PSW
                    terraform apply -auto-approve tfplan
                '''
            }
        }
        
        stage('Terraform Destroy') { //================================================
            when {
                expression { params.DESTROY_INFRASTRUCTURE == true }
            }
            steps {
                sh '''
                    export AWS_ACCESS_KEY_ID=$AWS_KEYS_USR
                    export AWS_SECRET_ACCESS_KEY=$AWS_KEYS_PSW
                    terraform destroy -auto-approve
                '''
            }
        }
    }
    post {
        always {
            echo 'Nettoyage du workspace...'
            sh 'rm -f tfplan'
        }
    }
}
