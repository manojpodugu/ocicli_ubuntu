#!/bin/bash

OUTPUT="/root/oci_instance_inventory.csv"
SNO=1

TENANCY_ID=$(grep '^tenancy=' /root/.oci/config | cut -d'=' -f2)

echo "S.No,DisplayName,RegionName,CompartmentName,State,InstanceOCID,OSName,OSVersion" > "$OUTPUT"

REGIONS=$(oci iam region-subscription list \
  --query 'data[]."region-name"' \
  --output json | jq -r '.[]')

COMPARTMENTS=$(oci iam compartment list \
  --compartment-id "$TENANCY_ID" \
  --compartment-id-in-subtree true \
  --access-level ACCESSIBLE \
  --all \
  --output json | jq -r '.data[].id')

COMPARTMENTS="$TENANCY_ID"$'\n'"$COMPARTMENTS"

for REGION in $REGIONS
do
    echo "Processing region: $REGION"

    while IFS= read -r COMPARTMENT_ID
    do
        [ -z "$COMPARTMENT_ID" ] && continue

        COMPARTMENT_NAME=$(oci iam compartment get \
          --compartment-id "$COMPARTMENT_ID" \
          --region "$REGION" \
          --query 'data.name' \
          --raw-output 2>/dev/null)

        [ -z "$COMPARTMENT_NAME" ] && continue

        INSTANCES=$(oci compute instance list \
          --compartment-id "$COMPARTMENT_ID" \
          --region "$REGION" \
          --all \
          --output json 2>/dev/null)

        echo "$INSTANCES" | jq -c '.data[]' 2>/dev/null |
        while IFS= read -r INSTANCE
        do
            DISPLAY_NAME=$(echo "$INSTANCE" | jq -r '."display-name"')
            STATE=$(echo "$INSTANCE" | jq -r '."lifecycle-state"')
            INSTANCE_OCID=$(echo "$INSTANCE" | jq -r '.id')
            IMAGE_ID=$(echo "$INSTANCE" | jq -r '."image-id"')

            IMAGE_INFO=$(oci compute image get \
              --image-id "$IMAGE_ID" \
              --region "$REGION" \
              --output json 2>/dev/null)

            OS_NAME=$(echo "$IMAGE_INFO" | jq -r '.data."operating-system" // "Unknown"')

            OS_VERSION=$(echo "$IMAGE_INFO" | jq -r '.data."operating-system-version" // "Unknown"')

            printf '%s,%s,%s,%s,%s,%s,%s,%s\n' \
              "$SNO" \
              "$DISPLAY_NAME" \
              "$REGION" \
              "$COMPARTMENT_NAME" \
              "$STATE" \
              "$INSTANCE_OCID" \
              "$OS_NAME" \
              "$OS_VERSION" >> "$OUTPUT"

            SNO=$((SNO + 1))
        done

    done <<< "$COMPARTMENTS"
done


TOTAL_INSTANCES=$(tail -n +2 "$OUTPUT" | wc -l)

echo "" >> "$OUTPUT"
echo "Overall Instance Count,$TOTAL_INSTANCES" >> "$OUTPUT"

echo
echo "Inventory completed."
echo "Total instances: $TOTAL_INSTANCES"
echo "Output file: $OUTPUT"
