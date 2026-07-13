interface Env {
	FINALIZE_FUNCTION_URL: string;
	INTERNAL_ADMIN_SECRET: string;
	NURA_BUCKET: R2Bucket;
}

interface R2EventNotification {
	action: 'PutObject' | 'CopyObject' | 'CompleteMultipartUpload' | 'DeleteObject' | string;
	bucket: string;
	object?: {
		key?: string;
		size?: number;
		eTag?: string;
	};
	eventTime: string;
}

export default {
	async queue(batch, env): Promise<void> {
		for (const message of batch.messages) {
			try {
				await processNotification(message.body, env);
				message.ack();
			} catch (error) {
				console.error('[r2-trigger] message failed', error);
				message.retry();
			}
		}
	},
} satisfies ExportedHandler<Env, R2EventNotification>;

async function processNotification(event: R2EventNotification, env: Env): Promise<void> {
	if (!['PutObject', 'CopyObject', 'CompleteMultipartUpload'].includes(event.action)) return;

	const rawStoragePath = event.object?.key ?? '';
	if (!rawStoragePath.startsWith('raw/')) return;

	const response = await fetch(env.FINALIZE_FUNCTION_URL, {
		method: 'POST',
		headers: {
			Authorization: `Bearer ${env.INTERNAL_ADMIN_SECRET}`,
			'Content-Type': 'application/json',
		},
		body: JSON.stringify({ rawStoragePath, storagePath: rawStoragePath }),
	});

	if (!response.ok) {
		const body = await response.text();
		throw new Error(`finalize-track-transcode failed: ${response.status} ${body}`);
	}

	console.log('[r2-trigger] finalized raw upload', rawStoragePath);
}
