import { constants as fsConstants } from "node:fs";
import { open as fsOpen, type FileHandle } from "node:fs/promises";
import { create as ghactionsArtifact, type DownloadResponse as GitHubActionsArtifactDownloadResponse, type UploadResponse as GitHubActionsArtifactUploadResponse } from "@actions/artifact";
import { restoreCache as ghactionsCacheRestoreCache, saveCache as ghactionsCacheSaveCache } from "@actions/cache";
import { debug as ghactionsDebug, getIDToken as ghactionsGetOpenIDConnectToken } from "@actions/core";
import { cacheDir as ghactionsToolCacheCacheDirectory, cacheFile as ghactionsToolCacheCacheFile, downloadTool as ghactionsToolCacheDownloadTool, extract7z as ghactionsToolCacheExtract7z, extractTar as ghactionsToolCacheExtractTar, extractXar as ghactionsToolCacheExtractXar, extractZip as ghactionsToolCacheExtractZip, find as ghactionsToolCacheFind, findAllVersions as ghactionsToolCacheFindAllVersions } from "@actions/tool-cache";
const exchangeFileHandle: FileHandle = await fsOpen(process.argv.slice(2)[0], fsConstants.O_RDWR | fsConstants.O_NOFOLLOW);
const input = JSON.parse(await exchangeFileHandle.readFile({ encoding: "utf8" }));
async function exchangeFileWrite(data: Record<string, unknown>): Promise<void> {
	await exchangeFileHandle.truncate(0);
	return exchangeFileHandle.writeFile(JSON.stringify(data), { encoding: "utf8" });
}
function resolveError(reason: string | Error | RangeError | ReferenceError | SyntaxError | TypeError): Promise<void> {
	let output: Record<string, unknown> = {
		isSuccess: false
	};
	if (typeof reason === "string") {
		output.reason = reason;
	} else {
		let message = `${reason.name}: ${reason.message}`;
		if (typeof reason.stack !== "undefined") {
			message += `\n${reason.stack}`;
		}
		output.reason = message;
	}
	return exchangeFileWrite(output);
}
function resolveResult(result: unknown): Promise<void> {
	return exchangeFileWrite({
		isSuccess: true,
		result
	});
}
switch (input.wrapperName) {
	case "$fail":
		ghactionsDebug(input.message);
		await resolveError("Test");
		break;
	case "$success":
		ghactionsDebug(input.message);
		await resolveResult("Hello, world!");
		break;
	case "artifact/download":
		try {
			let result: GitHubActionsArtifactDownloadResponse = await ghactionsArtifact().downloadArtifact(input.name, input.destination, { createArtifactFolder: input.createSubfolder });
			await resolveResult({
				name: result.artifactName,
				path: result.downloadPath
			});
		} catch (error) {
			await resolveError(error);
		}
		break;
	case "artifact/download-all":
		try {
			let result: GitHubActionsArtifactDownloadResponse[] = await ghactionsArtifact().downloadAllArtifacts(input.destination);
			await resolveResult(result.map((value: GitHubActionsArtifactDownloadResponse) => {
				return {
					name: value.artifactName,
					path: value.downloadPath
				};
			}));
		} catch (error) {
			await resolveError(error);
		}
		break;
	case "artifact/upload":
		try {
			let result: GitHubActionsArtifactUploadResponse = await ghactionsArtifact().uploadArtifact(input.name, input.items, input.rootDirectory, {
				continueOnError: input.continueOnError,
				retentionDays: input.retentionDays
			});
			await resolveResult({
				name: result.artifactName,
				items: result.artifactItems,
				size: result.size,
				failedItems: result.failedItems
			});
		} catch (error) {
			await resolveError(error);
		}
		break;
	case "cache/restore":
		try {
			let result: string | undefined = await ghactionsCacheRestoreCache(input.paths, input.primaryKey, input.restoreKeys, {
				downloadConcurrency: input.downloadConcurrency,
				lookupOnly: input.lookup,
				segmentTimeoutInMs: input.segmentTimeout,
				timeoutInMs: input.timeout,
				useAzureSdk: input.useAzureSdk
			});
			await resolveResult(result ?? null);
		} catch (error) {
			await resolveError(error);
		}
		break;
	case "cache/save":
		try {
			let result: number = await ghactionsCacheSaveCache(input.paths, input.key, {
				uploadChunkSize: input.uploadChunkSize,
				uploadConcurrency: input.uploadConcurrency
			});
			await resolveResult(result);
		} catch (error) {
			await resolveError(error);
		}
		break;
	case "open-id-connect/get-token":
		try {
			let result: string = await ghactionsGetOpenIDConnectToken(input.audience);
			await resolveResult(result);
		} catch (error) {
			await resolveError(error);
		}
		break;
	case "tool-cache/cache-directory":
		try {
			let result: string = await ghactionsToolCacheCacheDirectory(input.source, input.name, input.version, input.architecture);
			await resolveResult(result);
		} catch (error) {
			await resolveError(error);
		}
		break;
	case "tool-cache/cache-file":
		try {
			let result: string = await ghactionsToolCacheCacheFile(input.source, input.target, input.name, input.version, input.architecture);
			await resolveResult(result);
		} catch (error) {
			await resolveError(error);
		}
		break;
	case "tool-cache/download-tool":
		try {
			let result: string = await ghactionsToolCacheDownloadTool(input.url, input.destination, input.authorization, input.headers);
			await resolveResult(result);
		} catch (error) {
			await resolveError(error);
		}
		break;
	case "tool-cache/extract-7z":
		try {
			let result: string = await ghactionsToolCacheExtract7z(input.file, input.destination, input["7zrPath"]);
			await resolveResult(result);
		} catch (error) {
			await resolveError(error);
		}
		break;
	case "tool-cache/extract-tar":
		try {
			let result: string = await ghactionsToolCacheExtractTar(input.file, input.destination, input.flags);
			await resolveResult(result);
		} catch (error) {
			await resolveError(error);
		}
		break;
	case "tool-cache/extract-xar":
		try {
			let result: string = await ghactionsToolCacheExtractXar(input.file, input.destination, input.flags);
			await resolveResult(result);
		} catch (error) {
			await resolveError(error);
		}
		break;
	case "tool-cache/extract-zip":
		try {
			let result: string = await ghactionsToolCacheExtractZip(input.file, input.destination);
			await resolveResult(result);
		} catch (error) {
			await resolveError(error);
		}
		break;
	case "tool-cache/find":
		try {
			let result: string = ghactionsToolCacheFind(input.name, input.version, input.architecture);
			await resolveResult(result);
		} catch (error) {
			await resolveError(error);
		}
		break;
	case "tool-cache/find-all-versions":
		try {
			let result: string[] = ghactionsToolCacheFindAllVersions(input.name, input.architecture);
			await resolveResult(result);
		} catch (error) {
			await resolveError(error);
		}
		break;
	default:
		await resolveError(`\`${input.wrapperName}\` is not a valid NodeJS wrapper name! Most likely a mistake made by the contributors, please report this issue.`);
		break;
}
