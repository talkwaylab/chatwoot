<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import { MESSAGE_SIGNATURE_EDITOR_MENU_OPTIONS } from 'dashboard/constants/editor';
import FormButton from 'v3/components/Form/Button.vue';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';

const props = defineProps({
  messageSignature: {
    type: String,
    default: '',
  },
  signaturePosition: {
    type: String,
    default: 'start',
  },
  signatureSeparator: {
    type: String,
    default: 'new_line',
  },
});

const emit = defineEmits(['updateSignature']);

const { t } = useI18n();

const customEditorMenuList = MESSAGE_SIGNATURE_EDITOR_MENU_OPTIONS;
const signature = ref(props.messageSignature);
const signatureSettings = ref({
  position: props.signaturePosition,
  separator: props.signatureSeparator,
});

const positionOptions = [
  {
    id: 'start',
    name: t(
      'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.SIGNATURE_POSITION.OPTIONS.START'
    ),
  },
  {
    id: 'end',
    name: t(
      'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.SIGNATURE_POSITION.OPTIONS.END'
    ),
  },
];

const separatorOptions = [
  {
    id: 'new_line',
    name: t(
      'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.SIGNATURE_SEPARATOR.OPTIONS.NEW_LINE'
    ),
  },
  {
    id: 'horizontal_line',
    name: t(
      'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.SIGNATURE_SEPARATOR.OPTIONS.HORIZONTAL_LINE'
    ),
  },
];

const selectedPosition = ref(
  positionOptions.find(opt => opt.id === signatureSettings.value.position) ||
    positionOptions[0]
);
const selectedSeparator = ref(
  separatorOptions.find(opt => opt.id === signatureSettings.value.separator) ||
    separatorOptions[0]
);

watch(
  () => props.messageSignature ?? '',
  newValue => {
    signature.value = newValue;
  }
);

watch(
  () => props.signaturePosition,
  newValue => {
    signatureSettings.value.position = newValue;
    selectedPosition.value =
      positionOptions.find(opt => opt.id === newValue) || positionOptions[0];
  }
);

watch(
  () => props.signatureSeparator,
  newValue => {
    signatureSettings.value.separator = newValue;
    selectedSeparator.value =
      separatorOptions.find(opt => opt.id === newValue) || separatorOptions[0];
  }
);

watch(selectedPosition, newValue => {
  if (newValue) {
    signatureSettings.value.position = newValue.id;
  }
});

watch(selectedSeparator, newValue => {
  if (newValue) {
    signatureSettings.value.separator = newValue.id;
  }
});

const updateSignature = () => {
  emit('updateSignature', signature.value, signatureSettings.value);
};
</script>

<template>
  <form class="flex flex-col gap-6" @submit.prevent="updateSignature()">
    <div class="flex flex-col gap-4 mb-6">
      <div>
        <label class="block text-sm font-medium mb-2 text-ash-900">
          {{
            $t(
              'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.SIGNATURE_POSITION.LABEL'
            )
          }}
        </label>
        <SingleSelect
          v-model="selectedPosition"
          :options="positionOptions"
          :placeholder="
            $t(
              'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.SIGNATURE_POSITION.LABEL'
            )
          "
        />
      </div>
      <div>
        <label class="block text-sm font-medium mb-2 text-ash-900">
          {{
            $t(
              'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.SIGNATURE_SEPARATOR.LABEL'
            )
          }}
        </label>
        <SingleSelect
          v-model="selectedSeparator"
          :options="separatorOptions"
          :placeholder="
            $t(
              'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.SIGNATURE_SEPARATOR.LABEL'
            )
          "
        />
      </div>
    </div>
    <WootMessageEditor
      id="message-signature-input"
      v-model="signature"
      class="message-editor h-[10rem] !px-3"
      is-format-mode
      :placeholder="$t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE.PLACEHOLDER')"
      :enabled-menu-options="customEditorMenuList"
      :enable-suggestions="false"
      show-image-resize-toolbar
    />
    <FormButton
      type="submit"
      color-scheme="primary"
      variant="solid"
      size="large"
    >
      {{ $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.BTN_TEXT') }}
    </FormButton>
  </form>
</template>
