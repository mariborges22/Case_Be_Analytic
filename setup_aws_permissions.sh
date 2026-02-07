#!/bin/bash

# ==============================================================================
# Script para configurar permissões do usuário case_be_analytic na AWS
# ==============================================================================

USER_NAME="case_be_analytic"
POLICY_NAME="CaseBeAnalyticTerraformPolicy"

echo "🚀 Iniciando configuração de permissões para o usuário: $USER_NAME"

# 1. Criar o arquivo de política JSON
cat <<EOF > terraform_policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "TerraformS3Permissions",
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:PutBucketVersioning",
                "s3:PutEncryptionConfiguration",
                "s3:PutBucketPublicAccessBlock",
                "s3:GetBucketLocation",
                "s3:ListBucket",
                "s3:DeleteBucket"
            ],
            "Resource": "*"
        },
        {
            "Sid": "TerraformIAMPermissions",
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:GetRole",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:GetRolePolicy",
                "iam:CreateInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:GetInstanceProfile",
                "iam:AddRoleToInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:PassRole"
            ],
            "Resource": "*"
        }
    ]
}
EOF

# 2. Criar a política na AWS
echo "📑 Criando política gerenciada..."
POLICY_ARN=$(aws iam create-policy --policy-name $POLICY_NAME --policy-document file://terraform_policy.json --query 'Policy.Arn' --output text 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "✅ Política criada com sucesso: $POLICY_ARN"
else
    echo "ℹ️ A política já existe ou houve um erro, tentando obter o ARN existente..."
    POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)
fi

# 3. Anexar a política ao usuário
echo "🔗 Anexando política ao usuário $USER_NAME..."
aws iam attach-user-policy --user-name $USER_NAME --policy-arn $POLICY_ARN

if [ $? -eq 0 ]; then
    echo "✅ Política anexada com sucesso!"
else
    echo "❌ Erro ao anexar política. Verifique se o usuário '$USER_NAME' existe."
    exit 1
fi

# Limpeza
rm terraform_policy.json

echo "✨ Configuração concluída! Agora o Terraform terá as permissões necessárias."
