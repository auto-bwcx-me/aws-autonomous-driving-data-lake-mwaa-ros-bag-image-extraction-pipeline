#!/bin/bash
# ./check_role.sh

prefix="EC2-auto-Cloud9"

echo "Name definition of role, policy and instance profile."
role_name=${prefix}"-Role"
policy_name=${prefix}"-Policy"
ins_profile_name=${prefix}"-InstanceProfile"

echo "Check policy of: $policy_name"
policy_arn=$(aws iam list-policies --scope Local --output json | grep Arn | grep ${policy_name} | awk -F '"' '{print $4}')
# arn:aws:iam::123456789012:policy/ee-Policy
if [ ${#policy_arn} -lt 6 ]; then
    policy_arn=$(aws iam create-policy --policy-name ${policy_name} --policy-document file://iam-policy.json --output json | jq -r .Policy.Arn)
    echo "Create policy ${policy_name}."
fi

echo "Check role of: $role_name"
acc_id=$(echo ${policy_arn} | awk -F ":" '{print $5}')
role_arn=$(aws iam get-role --role-name ${role_name} --output json | jq -r .Role.Arn)
# arn:aws:iam::351452666966:role/ee-Role
if [ ${#role_arn} -lt 6 ]; then
    sed "s/123456789012/$acc_id/g" iam-role-trust-policy.json >temp.json
    aws iam create-role --role-name ${role_name} --assume-role-policy-document file://temp.json
    rm -f temp.json
    echo "Create role ${role_name}."
fi

echo "Check role and policy attachment"
role_policy=$(aws iam list-attached-role-policies --role-name ${role_name} | grep ${policy_name})
if [ ${#role_policy} -lt 6 ]; then
    aws iam attach-role-policy --role-name ${role_name} --policy-arn ${policy_arn}
    echo "Attach role ${role_name} with policy ${policy_name}."
fi

echo "Check instance profile of: $ins_profile_name"
ins_profile_arn=$(aws iam get-instance-profile --instance-profile-name ${ins_profile_name} --output json | jq -r .InstanceProfile.Arn)
# arn:aws:iam::351452666966:instance-profile/ee-InstanceProfile
if [ ${#ins_profile_arn} -lt 6 ]; then
    aws iam create-instance-profile --instance-profile-name ${ins_profile_name}
    echo "Create instance profile ${ins_profile_name}."
    aws iam add-role-to-instance-profile --role-name ${role_name} --instance-profile-name ${ins_profile_name}
    echo "Attach instance profile ${ins_profile_name} with role ${role_name}."
fi

ins_id=$(curl http://169.254.169.254/latest/meta-data/instance-id)
aws ec2 associate-iam-instance-profile --instance-id i-123456789abcde123 \
    --iam-instance-profile Name=${ins_profile_name}
