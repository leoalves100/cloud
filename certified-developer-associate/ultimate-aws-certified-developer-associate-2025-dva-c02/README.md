# AWS Certified Developer – Associate(DVA-C02)

Valide a proficiência técnica no desenvolvimento, teste, implantação e depuração de aplicações baseadas na Nuvem AWS

## Executando terraform

Exporte as variáveis de ambiente geradas para seu usuário IAM

```bash
export AWS_ACCESS_KEY_ID="<aws-access-key-id>"
export AWS_SECRET_ACCESS_KEY="aws-secret-access-key"
export AWS_REGION="us-east-1"
terraform plan/apply
```

## Listar imagens EC2

```bash
# Lista todas as imagens do proprietário Amazon
aws ec2 describe-images --owners amazon

# Lista todas as imagens com o filtro amazon linux e arquitetura arm64
aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-2023.7*" "Name=architecture,Values=arm64"
```
